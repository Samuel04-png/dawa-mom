// Rudo's conversational front-end to the REAL DawaMom booking backend.
//
// This module never creates appointments or decides prices itself. Every
// service, clinic, clinician, slot, and appointment value here comes from
// the same tables/RPCs/Edge Functions the normal Flutter booking sheet uses:
//   - public.service_catalog (read directly)
//   - clinics table + clinician-directory Edge Function (real availability)
//   - book_dawa_mom_appointment RPC (the exact booking RPC Flutter calls)
//
// Payment is intentionally NOT handled here. Once an appointment is created
// and is_paid_snapshot is true, the Flutter client reuses the existing
// LipilaPaymentRepository/payment UI, exactly like the normal booking sheet.
// The LLM never sees or sets a payment amount.

import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

type SupabaseAny = SupabaseClient<any, "public", any>;

export type ServiceRow = {
  id: string;
  external_service_id: string | null;
  name: string;
  description: string | null;
  category: string | null;
  is_paid: boolean;
  price: number;
  currency: string;
};

type ClinicRow = { id: string; name: string };
type ClinicianRow = {
  id: string;
  displayName: string;
  professionalTitle: string | null;
  speciality: string | null;
  clinicId: string;
  clinicName: string;
};
type SlotCandidate = {
  clinicId: string;
  clinicName: string;
  clinicianId: string;
  clinicianName: string;
  date: string;
  startTime: string;
  endTime: string;
};

export type BookingState = {
  service_id?: string;
  service_name?: string;
  is_paid?: boolean;
  price?: number;
  currency?: string;
  clinic_id?: string;
  clinic_name?: string;
  clinician_id?: string;
  clinician_name?: string;
  clinician_preference?: "any" | "named";
  clinician_name_query?: string;
  date_text?: string;
  time_text?: string;
  wants_earliest?: boolean;
  date?: string;
  start_time?: string;
  end_time?: string;
  awaiting_confirmation?: boolean;
  idempotency_key?: string;
  candidate_services?: Array<
    { id: string; name: string; price: number; currency: string; is_paid: boolean }
  >;
  candidate_clinics?: ClinicRow[];
  candidate_slots?: SlotCandidate[];
  appointment_id?: string;
  stage?: "collecting" | "awaiting_payment" | "done";
};

export type BookingAction =
  | { type: "service_options"; services: BookingState["candidate_services"] }
  | { type: "clinic_options"; clinics: ClinicRow[] }
  | {
    type: "slot_options";
    slots: Array<
      { index: number; clinicName: string; clinicianName: string; date: string; startTime: string; endTime: string }
    >;
  }
  | {
    type: "booking_summary";
    summary: {
      serviceName: string;
      isPaid: boolean;
      price: number;
      currency: string;
      date: string;
      startTime: string;
      clinicName: string;
      clinicianName: string;
    };
  }
  | {
    type: "payment_required";
    appointment: {
      id: string;
      serviceName: string;
      price: number;
      currency: string;
      date: string;
      startTime: string;
      clinicName: string;
    };
  }
  | {
    type: "booking_success";
    appointment: { id: string; serviceName: string; date: string; startTime: string; clinicName: string };
  }
  | { type: "booking_error"; error: string; retryable: boolean };

export type StructuredAction =
  | { type: "select_service"; service_id: string }
  | { type: "select_clinic"; clinic_id: string }
  | { type: "select_slot"; index: number }
  | { type: "confirm" }
  | { type: "change" }
  | { type: "cancel" };

export type ExtractedIntent = {
  intent:
    | "book"
    | "select_service"
    | "set_datetime"
    | "set_clinician"
    | "confirm"
    | "change"
    | "cancel"
    | "other";
  service_query?: string;
  date_text?: string;
  time_text?: string;
  clinician_preference?: "any" | "named" | "unspecified";
  clinician_name_text?: string;
  confirm?: boolean;
  wants_earliest?: boolean;
};

export const RESERVED_ACTION_PREFIX = "__rudo_action__:";

export function parseStructuredAction(message: string): StructuredAction | null {
  if (!message.startsWith(RESERVED_ACTION_PREFIX)) return null;
  try {
    const parsed = JSON.parse(message.slice(RESERVED_ACTION_PREFIX.length));
    if (parsed && typeof parsed === "object" && typeof parsed.type === "string") {
      return parsed as StructuredAction;
    }
  } catch {
    // Fall through to null; treated as an ordinary chat message.
  }
  return null;
}

export function looksLikeBookingMessage(message: string, hasActiveBooking: boolean): boolean {
  if (hasActiveBooking) return true;
  const t = message.toLowerCase();
  return /\b(book|appointment|schedule a visit|ultrasound|scan|consult|screening|checkup|check-up|see (a|the) (doctor|nurse|midwife)|clinic visit)\b/
    .test(t);
}

export async function runBookingTurn(options: {
  supabase: SupabaseAny;
  supabaseUrl: string;
  authorization: string;
  message: string;
  priorState: BookingState;
  serviceCatalog: ServiceRow[];
  geminiApiKey: string | null;
  geminiModel: string;
}): Promise<{ reply: string; action: BookingAction | null; state: BookingState }> {
  const { supabase, message, priorState, serviceCatalog } = options;
  let state: BookingState = { ...priorState };

  const structured = parseStructuredAction(message);

  if (structured?.type === "cancel") {
    return { reply: "No problem. Let me know when you would like to book.", action: null, state: {} };
  }

  if (structured?.type === "change") {
    return resolvePipeline({ ...state, awaiting_confirmation: false }, options);
  }

  if (structured?.type === "select_service") {
    const service = serviceCatalog.find((s) => s.id === structured.service_id);
    if (!service) {
      return { reply: "That service is no longer available. Please choose another.", action: null, state };
    }
    state = {
      service_id: service.id,
      service_name: service.name,
      is_paid: service.is_paid,
      price: service.price,
      currency: service.currency,
    };
    return resolvePipeline(state, options);
  }

  if (structured?.type === "select_clinic") {
    const clinic = state.candidate_clinics?.find((c) => c.id === structured.clinic_id);
    if (!clinic) {
      return { reply: "That clinic is no longer available.", action: null, state };
    }
    state.clinic_id = clinic.id;
    state.clinic_name = clinic.name;
    state.candidate_clinics = undefined;
    return resolvePipeline(state, options);
  }

  if (structured?.type === "select_slot") {
    const slot = state.candidate_slots?.[structured.index];
    if (!slot) {
      return { reply: "That time is no longer available. Please choose another.", action: null, state };
    }
    state.clinic_id = slot.clinicId;
    state.clinic_name = slot.clinicName;
    state.clinician_id = slot.clinicianId;
    state.clinician_name = slot.clinicianName;
    state.date = slot.date;
    state.start_time = slot.startTime;
    state.end_time = slot.endTime;
    state.candidate_slots = undefined;
    return resolvePipeline(state, options);
  }

  if (structured?.type === "confirm") {
    if (!state.awaiting_confirmation || !state.service_id || !state.clinic_id || !state.clinician_id || !state.date) {
      return resolvePipeline(state, options);
    }
    return createRealAppointment(state, options);
  }

  // Free-text turn: use Gemini only to extract structured fields. Gemini
  // never decides prices, availability, or booking success.
  const extracted = options.geminiApiKey
    ? await extractBookingFields(options.geminiApiKey, options.geminiModel, message, state, serviceCatalog)
    : { intent: "other" as const };

  if (extracted.intent === "cancel") {
    return { reply: "No problem. Let me know when you would like to book.", action: null, state: {} };
  }

  if (extracted.service_query) {
    const matched = matchService(extracted.service_query, serviceCatalog);
    if (matched) {
      state.service_id = matched.id;
      state.service_name = matched.name;
      state.is_paid = matched.is_paid;
      state.price = matched.price;
      state.currency = matched.currency;
    }
  }
  if (extracted.date_text) state.date_text = extracted.date_text;
  if (extracted.time_text) state.time_text = extracted.time_text;
  if (extracted.wants_earliest) state.wants_earliest = true;
  if (extracted.clinician_preference === "any") {
    state.clinician_preference = "any";
  } else if (extracted.clinician_preference === "named" && extracted.clinician_name_text) {
    state.clinician_preference = "named";
    state.clinician_name_query = extracted.clinician_name_text;
  }

  if (extracted.confirm === true && priorState.awaiting_confirmation) {
    return createRealAppointment(state, options);
  }

  return resolvePipeline(state, options);
}

async function resolvePipeline(
  state: BookingState,
  options: Parameters<typeof runBookingTurn>[0],
): Promise<{ reply: string; action: BookingAction | null; state: BookingState }> {
  const { supabase, supabaseUrl, authorization, serviceCatalog } = options;

  if (!state.service_id) {
    const candidates = serviceCatalog.slice(0, 6).map((s) => ({
      id: s.id,
      name: s.name,
      price: s.price,
      currency: s.currency,
      is_paid: s.is_paid,
    }));
    return {
      reply: "Which service would you like to book?",
      action: { type: "service_options", services: candidates },
      state: { ...state, candidate_services: candidates },
    };
  }

  if (!state.clinic_id) {
    const clinics = await fetchClinics(supabase);
    if (clinics.length === 0) {
      return {
        reply: "There are no clinics available for booking right now. Please try again later.",
        action: { type: "booking_error", error: "no_clinics", retryable: true },
        state,
      };
    }
    if (clinics.length === 1) {
      state.clinic_id = clinics[0].id;
      state.clinic_name = clinics[0].name;
    } else {
      return {
        reply: "Which clinic would you like to visit?",
        action: { type: "clinic_options", clinics },
        state: { ...state, candidate_clinics: clinics },
      };
    }
  }

  if (!state.clinician_id || !state.start_time || !state.date) {
    const slots = await searchSlots(supabaseUrl, authorization, state);
    if (slots.length === 0) {
      return {
        reply: "I couldn't find an available time for that. Would you like to try a different day?",
        action: { type: "booking_error", error: "no_availability", retryable: true },
        state,
      };
    }
    if (state.wants_earliest || slots.length === 1 || state.clinician_preference === "any") {
      const first = slots[0];
      state.clinic_id = first.clinicId;
      state.clinic_name = first.clinicName;
      state.clinician_id = first.clinicianId;
      state.clinician_name = first.clinicianName;
      state.date = first.date;
      state.start_time = first.startTime;
      state.end_time = first.endTime;
    } else {
      return {
        reply: "Here are the available times I found:",
        action: {
          type: "slot_options",
          slots: slots.map((slot, index) => ({
            index,
            clinicName: slot.clinicName,
            clinicianName: slot.clinicianName,
            date: slot.date,
            startTime: slot.startTime,
            endTime: slot.endTime,
          })),
        },
        state: { ...state, candidate_slots: slots },
      };
    }
  }

  if (!state.awaiting_confirmation) {
    state.awaiting_confirmation = true;
    state.idempotency_key = crypto.randomUUID();
    return {
      reply: buildSummaryText(state),
      action: {
        type: "booking_summary",
        summary: {
          serviceName: state.service_name ?? "Service",
          isPaid: state.is_paid ?? false,
          price: state.price ?? 0,
          currency: state.currency ?? "ZMW",
          date: state.date ?? "",
          startTime: state.start_time ?? "",
          clinicName: state.clinic_name ?? "Clinic",
          clinicianName: state.clinician_name ?? "Any available clinician",
        },
      },
      state,
    };
  }

  return {
      reply: "Please confirm this appointment:",
    state,
  };
}

async function createRealAppointment(
  state: BookingState,
  options: Parameters<typeof runBookingTurn>[0],
): Promise<{ reply: string; action: BookingAction | null; state: BookingState }> {
  const { supabase } = options;
  if (!state.service_id || !state.clinic_id || !state.clinician_id || !state.date || !state.start_time || !state.end_time) {
    return resolvePipeline(state, options);
  }

  const idempotencyKey = state.idempotency_key ?? crypto.randomUUID();
  const { data, error } = await supabase.rpc("book_dawa_mom_appointment", {
    p_clinic_id: state.clinic_id,
    p_clinician_id: state.clinician_id,
    p_appointment_date: state.date,
    p_start_time: `${state.start_time}:00`,
    p_end_time: `${state.end_time}:00`,
    p_appointment_type: "maternal_health",
    p_reason: null,
    p_notes: null,
    p_idempotency_key: idempotencyKey,
    p_service_id: state.service_id,
  });

  if (error) {
    const retryable = error.code === "23505" || error.code === "23514";
    return {
      reply: error.code === "23505"
        ? "That time was just taken. Would you like to try another time?"
        : "The appointment could not be created. Please try again.",
      action: { type: "booking_error", error: error.code ?? "unknown", retryable },
      state: retryable ? { ...state, awaiting_confirmation: false, idempotency_key: undefined } : {},
    };
  }

  const row: Record<string, unknown> = Array.isArray(data) ? (data[0] ?? {}) : (data ?? {});
  const appointmentId = String(row.id ?? "");
  const isPaid = Boolean(row.is_paid_snapshot);
  const summary = {
    id: appointmentId,
    serviceName: String(row.service_name_snapshot ?? state.service_name ?? "Service"),
    price: Number(row.price_snapshot ?? state.price ?? 0),
    currency: String(row.currency_snapshot ?? state.currency ?? "ZMW"),
    date: state.date,
    startTime: state.start_time,
    clinicName: state.clinic_name ?? "Clinic",
  };

  if (isPaid) {
    return {
      reply: "I’ve reserved your appointment. Please complete payment to finalise it.",
      action: { type: "payment_required", appointment: summary },
      state: { appointment_id: appointmentId, stage: "awaiting_payment" },
    };
  }

  return {
    reply: "Your appointment request has been saved. The clinic will confirm it.",
    action: {
      type: "booking_success",
      appointment: {
        id: appointmentId,
        serviceName: summary.serviceName,
        date: summary.date,
        startTime: summary.startTime,
        clinicName: summary.clinicName,
      },
    },
    state: {},
  };
}

function buildSummaryText(state: BookingState): string {
  const paidLine = state.is_paid ? `${state.currency ?? "ZMW"} ${(state.price ?? 0).toFixed(2)}` : "Free";
  return [
    "Please confirm this appointment:",
    state.service_name ?? "",
    `${state.date ?? ""} · ${state.start_time ?? ""}`,
    state.clinic_name ?? "",
    state.clinician_name ?? "Any available clinician",
    paidLine,
  ].filter(Boolean).join("\n");
}

async function fetchClinics(supabase: SupabaseAny): Promise<ClinicRow[]> {
  const { data } = await supabase
    .from("clinics")
    .select("id,name")
    .not("dawa_clinician_clinic_id", "is", null)
    .order("name");
  return (data ?? []).map((row: Record<string, unknown>) => ({
    id: String(row.id),
    name: (row.name as string) ?? "Clinic",
  }));
}

async function fetchCliniciansForClinic(
  supabaseUrl: string,
  authorization: string,
  clinicId: string,
): Promise<ClinicianRow[]> {
  const response = await fetch(`${supabaseUrl}/functions/v1/clinician-directory`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: authorization },
    body: JSON.stringify({ action: "list", clinic_id: clinicId }),
  });
  if (!response.ok) return [];
  const payload = await response.json().catch(() => ({}));
  const list = Array.isArray(payload?.clinicians) ? payload.clinicians : [];
  return list
    .filter((c: Record<string, unknown>) => c.is_active !== false && c.is_bookable !== false)
    .map((c: Record<string, unknown>) => ({
      id: String(c.id),
      displayName: (c.display_name as string) ?? "Health worker",
      professionalTitle: (c.professional_title as string) ?? null,
      speciality: (c.speciality as string) ?? null,
      clinicId: String(c.clinic_id ?? clinicId),
      clinicName: (c.clinic_name as string) ?? "Clinic",
    }));
}

async function fetchAvailability(
  supabaseUrl: string,
  authorization: string,
  clinicianId: string,
  dateId: string,
): Promise<Array<{ start_time: string; end_time: string; is_available: boolean }>> {
  const response = await fetch(`${supabaseUrl}/functions/v1/clinician-directory`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: authorization },
    body: JSON.stringify({ action: "availability", clinician_id: clinicianId, date: dateId }),
  });
  if (!response.ok) return [];
  const payload = await response.json().catch(() => ({}));
  return Array.isArray(payload?.slots) ? payload.slots : [];
}

async function searchSlots(
  supabaseUrl: string,
  authorization: string,
  state: BookingState,
): Promise<SlotCandidate[]> {
  if (!state.clinic_id) return [];
  const dates = resolveDateCandidates(state.date_text, state.wants_earliest === true);
  const window = resolveTimeWindow(state.time_text);
  const clinicians = await fetchCliniciansForClinic(supabaseUrl, authorization, state.clinic_id);
  const pool = state.clinician_preference === "named" && state.clinician_name_query
    ? clinicians.filter((c) =>
      c.displayName.toLowerCase().includes(state.clinician_name_query!.toLowerCase())
    )
    : clinicians;
  if (pool.length === 0) return [];

  const results: SlotCandidate[] = [];
  for (const date of dates) {
    for (const clinician of pool) {
      const slots = await fetchAvailability(supabaseUrl, authorization, clinician.id, date);
      const available = slots
        .filter((s) => s.is_available)
        .filter((s) => matchesWindow(s.start_time, window))
        .sort((a, b) => a.start_time.localeCompare(b.start_time));
      for (const slot of available) {
        results.push({
          clinicId: clinician.clinicId,
          clinicName: clinician.clinicName,
          clinicianId: clinician.id,
          clinicianName: clinician.displayName,
          date,
          startTime: normalizeTime(slot.start_time),
          endTime: normalizeTime(slot.end_time),
        });
        if (results.length >= 6) return results;
      }
    }
    if (results.length > 0 && !state.wants_earliest) break;
  }
  return results;
}

function normalizeTime(value: string): string {
  const parts = value.split(":");
  if (parts.length < 2) return value;
  return `${parts[0].padStart(2, "0")}:${parts[1].padStart(2, "0")}`;
}

function matchesWindow(startTime: string, window: { min?: string; max?: string }): boolean {
  if (!window.min && !window.max) return true;
  const time = normalizeTime(startTime);
  if (window.min && time < window.min) return false;
  if (window.max && time > window.max) return false;
  return true;
}

function resolveDateCandidates(dateText: string | undefined, wantsEarliest: boolean): string[] {
  const today = new Date();
  const fmt = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const addDays = (n: number) => {
    const d = new Date(today);
    d.setDate(d.getDate() + n);
    return d;
  };
  const text = (dateText ?? "").toLowerCase().trim();

  if (!text || wantsEarliest) {
    return Array.from({ length: 7 }, (_, i) => fmt(addDays(i)));
  }
  if (text.includes("today")) return [fmt(addDays(0))];
  if (text.includes("tomorrow")) return [fmt(addDays(1))];

  const weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
  const weekdayIndex = weekdays.findIndex((w) => text.includes(w));
  if (weekdayIndex >= 0) {
    let delta = (weekdayIndex - today.getDay() + 7) % 7;
    if (delta === 0) delta = 7;
    return [fmt(addDays(delta))];
  }

  const explicitDate = text.match(/(\d{1,2})[/-](\d{1,2})/);
  if (explicitDate) {
    const day = parseInt(explicitDate[1], 10);
    const month = parseInt(explicitDate[2], 10);
    let candidate = new Date(today.getFullYear(), month - 1, day);
    if (candidate < today) candidate = new Date(today.getFullYear() + 1, month - 1, day);
    return [fmt(candidate)];
  }

  return Array.from({ length: 7 }, (_, i) => fmt(addDays(i)));
}

function resolveTimeWindow(text: string | undefined): { min?: string; max?: string } {
  const t = (text ?? "").toLowerCase();
  if (!t) return {};
  if (t.includes("morning")) return { min: "00:00", max: "11:59" };
  if (t.includes("afternoon")) return { min: "12:00", max: "16:59" };
  if (t.includes("evening")) return { min: "17:00", max: "23:59" };
  const explicit = t.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/);
  if (explicit) {
    let hour = parseInt(explicit[1], 10);
    const minute = explicit[2] ? parseInt(explicit[2], 10) : 0;
    const ampm = explicit[3];
    if (ampm === "pm" && hour < 12) hour += 12;
    if (ampm === "am" && hour === 12) hour = 0;
    if (hour >= 0 && hour < 24) {
      const value = `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
      return { min: value, max: value };
    }
  }
  return {};
}

const SERVICE_SYNONYMS: Record<string, string[]> = {
  ultrasound: ["scan", "ultrasound", "sonogram"],
  consultation: ["consultation", "consult", "checkup", "check-up", "general"],
  "sti screening": ["sti", "sexually transmitted"],
  "hpv test kit": ["hpv", "cervical"],
  "abo blood grouping": ["blood group", "blood grouping", "abo"],
  "birth kit": ["birth kit", "delivery kit"],
  "home based visit": ["home visit", "home based"],
  condoms: ["condom", "condoms"],
  injection: ["injection", "contraceptive injection"],
};

function matchService(query: string, catalog: ServiceRow[]): ServiceRow | null {
  const q = query.toLowerCase();
  const direct = catalog.find((s) => q.includes(s.name.toLowerCase()));
  if (direct) return direct;
  for (const [key, words] of Object.entries(SERVICE_SYNONYMS)) {
    if (words.some((w) => q.includes(w))) {
      const match = catalog.find((s) =>
        s.name.toLowerCase().includes(key) || (s.category ?? "").toLowerCase().includes(key)
      );
      if (match) return match;
    }
  }
  return catalog.find((s) => s.category && q.includes(s.category.toLowerCase())) ?? null;
}

async function extractBookingFields(
  apiKey: string,
  model: string,
  message: string,
  state: BookingState,
  catalog: ServiceRow[],
): Promise<ExtractedIntent> {
  const schema = {
    type: "OBJECT",
    properties: {
      intent: {
        type: "STRING",
        enum: ["book", "select_service", "set_datetime", "set_clinician", "confirm", "change", "cancel", "other"],
      },
      service_query: { type: "STRING" },
      date_text: { type: "STRING" },
      time_text: { type: "STRING" },
      clinician_preference: { type: "STRING", enum: ["any", "named", "unspecified"] },
      clinician_name_text: { type: "STRING" },
      confirm: { type: "BOOLEAN" },
      wants_earliest: { type: "BOOLEAN" },
    },
    required: ["intent"],
  };
  const prompt = [
    "You extract structured booking fields from a message for a maternal-health appointment assistant.",
    "You never invent prices, clinician names, dates, or availability. Only extract what the user actually said in THIS message.",
    `Known services: ${catalog.map((s) => s.name).join(", ")}`,
    `Current booking progress: ${JSON.stringify(state)}`,
    `User message: ${message}`,
    "Omit fields you are not confident the user specified.",
  ].join("\n");

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.1, responseMimeType: "application/json", responseSchema: schema },
        }),
      },
    );
    const raw = await response.json().catch(() => ({}));
    const text = raw?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text ?? "").join("") ?? "{}";
    const parsed = JSON.parse(text);
    if (parsed && typeof parsed === "object" && typeof parsed.intent === "string") {
      return parsed as ExtractedIntent;
    }
  } catch {
    // Fall through to a safe default; the pipeline will ask for clarification.
  }
  return { intent: "other" };
}
