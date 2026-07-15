import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

type OutboxJob = {
  id: string;
  appointment_id: string;
  recipient_kind: "patient" | "clinician";
  attempt_count: number;
};

type AppointmentContext = {
  appointment: Record<string, unknown>;
  patientName: string;
  patientEmail: string | null;
  clinicianName: string;
  clinicianEmail: string | null;
  clinicName: string;
};

type EmailMessage = {
  to: string;
  subject: string;
  html: string;
  text: string;
};

class DeliveryError extends Error {
  constructor(message: string, readonly retryable: boolean) {
    super(message);
  }
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const textValue = (value: unknown, fallback = "") => {
  const text = typeof value === "string" ? value.trim() : "";
  return text || fallback;
};

const escapeHtml = (value: unknown) =>
  textValue(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

const validEmail = (value: unknown): value is string =>
  typeof value === "string" &&
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());

const friendlyDate = (date: unknown, time: unknown) => {
  const rawDate = textValue(date);
  const rawTime = textValue(time).slice(0, 5);
  const parsed = new Date(`${rawDate}T${rawTime || "00:00"}:00`);
  if (Number.isNaN(parsed.valueOf())) return `${rawDate} ${rawTime}`.trim();
  return new Intl.DateTimeFormat("en", {
    dateStyle: "full",
    timeStyle: "short",
    // appointment time is stored as a clinic-local wall time (without zone),
    // so UTC formatting preserves the submitted hour instead of shifting it.
    timeZone: "UTC",
  }).format(parsed);
};

async function resolveClinicianEmail(
  supabase: SupabaseClient,
  doctor: Record<string, unknown>,
  appointmentId: string,
): Promise<string | null> {
  const profileId = textValue(doctor.profile_id);
  if (profileId) {
    const { data } = await supabase
      .from("profiles")
      .select("email")
      .eq("id", profileId)
      .maybeSingle();
    if (validEmail(data?.email)) return data.email.trim().toLowerCase();
  }

  const resolverUrl = Deno.env.get("DAWA_CLINICIAN_EMAIL_RESOLVER_URL");
  const resolverToken = Deno.env.get("DAWA_CLINICIAN_EMAIL_RESOLVER_TOKEN");
  if (!resolverUrl || !resolverToken) return null;

  const response = await fetch(resolverUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-dawa-integration-secret": resolverToken,
    },
    body: JSON.stringify({
      action: "resolve_appointment_recipient",
      clinician_id: textValue(doctor.id),
      appointment_id: appointmentId,
      source: "dawa_mom",
    }),
  });
  if (!response.ok) {
    throw new DeliveryError(
      `Clinician directory returned HTTP ${response.status}`,
      response.status === 408 || response.status === 429 || response.status >= 500,
    );
  }
  const payload = await response.json();
  return validEmail(payload?.email) ? payload.email.trim().toLowerCase() : null;
}

async function loadAppointmentContext(
  supabase: SupabaseClient,
  appointmentId: string,
  recipientKind: OutboxJob["recipient_kind"],
): Promise<AppointmentContext> {
  const { data: appointment, error: appointmentError } = await supabase
    .from("appointments")
    .select(
      "id,patient_id,mother_id,clinician_id,clinic_id,appointment_date,start_time,end_time,appointment_type,reason,status",
    )
    .eq("id", appointmentId)
    .single();
  if (appointmentError || !appointment) {
    throw new DeliveryError("Appointment is unavailable", false);
  }

  const [{ data: patient }, { data: mother }, { data: doctor }, { data: clinic }] =
    await Promise.all([
      supabase
        .from("profiles")
        .select("email,display_name")
        .eq("id", appointment.patient_id)
        .maybeSingle(),
      supabase
        .from("mothers")
        .select("name")
        .eq("id", appointment.mother_id)
        .maybeSingle(),
      supabase
        .from("doctors")
        .select("id,profile_id,name,professional_title,speciality")
        .eq("id", appointment.clinician_id)
        .maybeSingle(),
      supabase
        .from("clinics")
        .select("name")
        .eq("id", appointment.clinic_id)
        .maybeSingle(),
    ]);

  let patientEmail = validEmail(patient?.email)
    ? patient.email.trim().toLowerCase()
    : null;
  if (!patientEmail) {
    const { data } = await supabase.auth.admin.getUserById(appointment.patient_id);
    const authEmail = data.user?.email;
    if (validEmail(authEmail)) {
      patientEmail = authEmail.trim().toLowerCase();
    }
  }

  const doctorRow = (doctor ?? { id: appointment.clinician_id }) as Record<
    string,
    unknown
  >;
  const clinicianEmail = recipientKind === "clinician"
    ? await resolveClinicianEmail(supabase, doctorRow, appointmentId)
    : null;

  return {
    appointment,
    patientName: textValue(mother?.name, textValue(patient?.display_name, "Dawa Mom member")),
    patientEmail,
    clinicianName: textValue(doctor?.name, "Clinician"),
    clinicianEmail,
    clinicName: textValue(clinic?.name, "your selected clinic"),
  };
}

function buildMessage(
  job: OutboxJob,
  context: AppointmentContext,
): EmailMessage {
  const appointment = context.appointment;
  const when = friendlyDate(appointment.appointment_date, appointment.start_time);
  const reason = textValue(appointment.reason);
  if (job.recipient_kind === "patient") {
    if (!context.patientEmail) {
      throw new DeliveryError("Patient email is unavailable", false);
    }
    const subject = "We received your Dawa Mom appointment request";
    const text = [
      `Hello ${context.patientName},`,
      "We received your appointment request. It is pending until the clinic confirms it.",
      `When: ${when}`,
      `Clinician: ${context.clinicianName}`,
      `Clinic: ${context.clinicName}`,
      "You can review the request in Dawa Mom.",
    ].join("\n\n");
    return {
      to: context.patientEmail,
      subject,
      text,
      html: `<p>Hello ${escapeHtml(context.patientName)},</p>
        <p>We received your appointment request. <strong>It is pending until the clinic confirms it.</strong></p>
        <p><strong>When:</strong> ${escapeHtml(when)}<br>
        <strong>Clinician:</strong> ${escapeHtml(context.clinicianName)}<br>
        <strong>Clinic:</strong> ${escapeHtml(context.clinicName)}</p>
        <p>You can review the request in Dawa Mom.</p>`,
    };
  }

  if (!context.clinicianEmail) {
    throw new DeliveryError("Clinician email is unavailable", false);
  }
  const subject = `New Dawa Mom appointment request · ${when}`;
  const reasonText = reason ? `\n\nReason: ${reason}` : "";
  const reasonHtml = reason
    ? `<br><strong>Reason:</strong> ${escapeHtml(reason)}`
    : "";
  return {
    to: context.clinicianEmail,
    subject,
    text: [
      "A patient submitted a new appointment request through Dawa Mom.",
      `Patient: ${context.patientName}`,
      `When: ${when}`,
      `Clinic: ${context.clinicName}${reasonText}`,
      "This request is pending. Review it in the authorised clinician workflow.",
    ].join("\n\n"),
    html: `<p>A patient submitted a new appointment request through Dawa Mom.</p>
      <p><strong>Patient:</strong> ${escapeHtml(context.patientName)}<br>
      <strong>When:</strong> ${escapeHtml(when)}<br>
      <strong>Clinic:</strong> ${escapeHtml(context.clinicName)}${reasonHtml}</p>
      <p><strong>This request is pending.</strong> Review it in the authorised clinician workflow.</p>`,
  };
}

async function sendWithResend(
  message: EmailMessage,
  idempotencyKey: string,
): Promise<string | null> {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  const from = Deno.env.get("APPOINTMENT_EMAIL_FROM");
  if (!apiKey || !from) {
    throw new DeliveryError("Email provider is not configured", true);
  }
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": `dawa-mom-appointment-email-${idempotencyKey}`,
    },
    body: JSON.stringify({
      from,
      to: [message.to],
      subject: message.subject.replace(/[\r\n]+/g, " "),
      html: message.html,
      text: message.text,
    }),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = textValue(payload?.message, `Resend returned HTTP ${response.status}`);
    throw new DeliveryError(
      detail,
      response.status === 408 || response.status === 429 || response.status >= 500,
    );
  }
  return textValue(payload?.id) || null;
}

const retryAt = (attempt: number) => {
  const minutes = [5, 30, 120, 360][Math.min(Math.max(attempt - 1, 0), 3)];
  return new Date(Date.now() + minutes * 60_000).toISOString();
};

async function complete(
  supabase: SupabaseClient,
  parameters: Record<string, unknown>,
) {
  const { error } = await supabase.rpc("complete_appointment_email_job", parameters);
  if (error) throw error;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const workerSecret = Deno.env.get("APPOINTMENT_EMAIL_WORKER_SECRET");
  if (!workerSecret || request.headers.get("x-worker-secret") !== workerSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return json({ error: "Worker environment is incomplete" }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const workerId = `appointment-email-${crypto.randomUUID()}`;
  const { data, error } = await supabase.rpc("claim_appointment_email_jobs", {
    p_limit: 10,
    p_worker_id: workerId,
  });
  if (error) return json({ error: "Unable to claim email jobs" }, 500);

  const jobs = (data ?? []) as OutboxJob[];
  let sent = 0;
  let retrying = 0;
  let permanentlyFailed = 0;
  await Promise.all(
    jobs.map(async (job) => {
      let recipientEmail: string | null = null;
      try {
        const context = await loadAppointmentContext(
          supabase,
          job.appointment_id,
          job.recipient_kind,
        );
        const message = buildMessage(job, context);
        recipientEmail = message.to;
        const providerId = await sendWithResend(message, job.id);
        await complete(supabase, {
          p_job_id: job.id,
          p_worker_id: workerId,
          p_success: true,
          p_recipient_email: recipientEmail,
          p_provider_message_id: providerId,
        });
        sent++;
      } catch (caught) {
        const failure = caught instanceof DeliveryError
          ? caught
          : new DeliveryError("Unexpected delivery failure", true);
        const configuredAttempts = Number(
          Deno.env.get("APPOINTMENT_EMAIL_MAX_ATTEMPTS") ?? "4",
        );
        const maxAttempts = Number.isFinite(configuredAttempts) && configuredAttempts >= 1
          ? Math.trunc(configuredAttempts)
          : 4;
        const permanent = !failure.retryable || job.attempt_count >= maxAttempts;
        try {
          await complete(supabase, {
            p_job_id: job.id,
            p_worker_id: workerId,
            p_success: false,
            p_recipient_email: recipientEmail,
            p_error: failure.message,
            p_retry_at: permanent ? null : retryAt(job.attempt_count),
            p_permanent: permanent,
          });
          permanent ? permanentlyFailed++ : retrying++;
        } catch {
          console.error(`Could not finalize appointment email job ${job.id}`);
        }
      }
    }),
  );

  return json({ claimed: jobs.length, sent, retrying, permanently_failed: permanentlyFailed });
});
