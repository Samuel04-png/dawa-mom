import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

type Job = { id: string; profile_id: string; event_key: 'welcome' | 'reward_unlocked' | 'voucher_claimed'; attempt_count: number };
type Message = { to: string; subject: string; text: string; html: string };
type SupabaseAdmin = SupabaseClient<any, 'public', any>;

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const secret = Deno.env.get('DAWA_MOM_EMAIL_WORKER_SECRET');
  if (!secret || request.headers.get('x-worker-secret') !== secret) {
    return json({ error: 'Unauthorized' }, 401);
  }
  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceRoleKey) return json({ error: 'Worker environment is incomplete' }, 500);
  const supabase = createClient(url, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const workerId = `dawa-mom-email-${crypto.randomUUID()}`;
  const { data, error } = await supabase.rpc('claim_dawa_mom_email_jobs', { p_limit: 10, p_worker_id: workerId });
  if (error) return json({ error: 'Unable to claim email jobs' }, 500);

  let sent = 0;
  let retrying = 0;
  for (const job of (data ?? []) as Job[]) {
    try {
      const message = await messageFor(supabase, job);
      const providerId = await send(message, job.id);
      await finish(supabase, { p_job_id: job.id, p_worker_id: workerId, p_success: true, p_provider_message_id: providerId });
      sent += 1;
    } catch (caught) {
      const retryable = !(caught instanceof DeliveryError) || caught.retryable;
      const permanent = !retryable || job.attempt_count >= 4;
      await finish(supabase, {
        p_job_id: job.id, p_worker_id: workerId, p_success: false,
        p_error: caught instanceof Error ? safeError(caught.message) : 'Delivery failed',
        p_retry_at: permanent ? null : new Date(Date.now() + retryMs(job.attempt_count)).toISOString(),
        p_permanent: permanent,
      });
      if (!permanent) retrying += 1;
    }
  }
  return json({ claimed: (data ?? []).length, sent, retrying });
});

class DeliveryError extends Error { constructor(message: string, readonly retryable: boolean) { super(message); } }

async function messageFor(supabase: SupabaseAdmin, job: Job): Promise<Message> {
  const { data: profile, error } = await supabase.from('profiles').select('display_name,email').eq('id', job.profile_id).maybeSingle();
  const record = profile as Record<string, unknown> | null;
  if (error || !validEmail(record?.email)) throw new DeliveryError('Recipient email is unavailable', false);
  const name = clean(record?.display_name, 'DawaMom member');
  const content = templates(job.event_key, name);
  return { to: record.email.trim().toLowerCase(), ...content };
}

function templates(event: Job['event_key'], name: string): Omit<Message, 'to'> {
  const body = event === 'welcome'
    ? ['Welcome to DawaMom.', 'You can use the app to follow your health journey, learn, and find care when you need it.']
    : event === 'reward_unlocked'
      ? ['A DawaMom reward is ready.', 'Open your rewards in DawaMom to review it.']
      : ['Your DawaMom voucher is ready.', 'Open your rewards in DawaMom to view your private voucher reference.'];
  const subject = event === 'welcome' ? 'Welcome to DawaMom' : event === 'reward_unlocked' ? 'A DawaMom reward is ready' : 'Your DawaMom voucher is ready';
  const text = [`Hello ${name},`, ...body].join('\n\n');
  return { subject, text, html: `<p>Hello ${escapeHtml(name)},</p><p>${body.map(escapeHtml).join('</p><p>')}</p>` };
}

async function send(message: Message, id: string): Promise<string | null> {
  const key = Deno.env.get('RESEND_API_KEY');
  const from = Deno.env.get('DAWA_MOM_EMAIL_FROM');
  if (!key || !from) throw new DeliveryError('Email provider is not configured', true);
  const response = await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', 'Idempotency-Key': `dawa-mom-event-email-${id}` }, body: JSON.stringify({ from, to: [message.to], subject: message.subject, text: message.text, html: message.html }) });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) throw new DeliveryError(clean(payload?.message, `Resend returned HTTP ${response.status}`), response.status === 408 || response.status === 429 || response.status >= 500);
  return clean(payload?.id, '') || null;
}

async function finish(supabase: SupabaseAdmin, params: Record<string, unknown>) {
  const { error } = await supabase.rpc('complete_dawa_mom_email_job', params);
  if (error) throw error;
}
function validEmail(value: unknown): value is string { return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim()); }
function clean(value: unknown, fallback: string): string { const text = typeof value === 'string' ? value.trim() : ''; return text || fallback; }
function escapeHtml(value: string): string { return value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#039;'); }
function retryMs(attempt: number): number { return [5, 30, 120, 360][Math.min(Math.max(attempt - 1, 0), 3)] * 60_000; }
function safeError(value: string): string { return value.replace(/[\r\n]+/g, ' ').slice(0, 300); }
function json(body: unknown, status = 200) { return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } }); }
