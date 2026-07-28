import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type ChatRequest = {
  message?: string;
  session_id?: string;
  client_message_id?: string;
  metadata?: Record<string, unknown>;
};

type BackendReply = {
  reply: string;
  raw: unknown;
  source: string;
};

const defaultRudoBackendUrl = "https://rudo-mobile-app.vercel.app/api/chat";
const cannedBackendReplies = new Set([
  "Hello! I'm Rudo. I'm here to help with pregnancy and maternal health questions. What would you like to know?",
]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return jsonResponse({ error: "Missing Authorization header" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return jsonResponse({ error: "Supabase function environment is not configured" }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return jsonResponse({ error: "Invalid or expired session" }, 401);
  }

  let body: ChatRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const message = body.message?.trim();
  if (!message) {
    return jsonResponse({ error: "Message is required" }, 400);
  }

  const metadata = body.metadata ?? {};
  const phoneNumber = stringOrNull(metadata.phone_number);
  const userName = stringOrNull(metadata.user_name);

  const sessionResult = await getOrCreateSession(
    supabase,
    user.id,
    body.session_id,
    { phoneNumber, userName },
  );

  if ("error" in sessionResult) {
    return jsonResponse({ error: sessionResult.error }, sessionResult.status);
  }

  const sessionId = sessionResult.sessionId;
  const clientMessageId = body.client_message_id?.trim() || null;

  const { error: userMessageError } = await supabase
    .from("chat_messages")
    .insert({
      session_id: sessionId,
      role: "user",
      client_message_id: clientMessageId,
      source: "edge_function",
      content: message,
      payload: {
        type: "user_message",
        message,
        session_id: sessionId,
        client_message_id: clientMessageId,
        metadata: body.metadata ?? {},
      },
      metadata: {
        ...(body.metadata ?? {}),
        dedupe_enabled: clientMessageId !== null,
      },
    });

  if (userMessageError) {
    if (userMessageError.code === "23505") {
      return jsonResponse({
        duplicate: true,
        session_id: sessionId,
        message: "Duplicate client_message_id ignored",
      });
    }

    return jsonResponse({ error: userMessageError.message }, 500);
  }

  let backendReply: BackendReply;
  try {
    backendReply = await callRudoBackend({
      userId: user.id,
      sessionId,
      message,
      clientMessageId,
      metadata: body.metadata ?? {},
    });
  } catch (error) {
    return jsonResponse({
      error: error instanceof Error ? error.message : "Rudo backend request failed",
      session_id: sessionId,
    }, 502);
  }

  const { error: assistantMessageError } = await supabase
    .from("chat_messages")
    .insert({
      session_id: sessionId,
      role: "assistant",
      source: backendReply.source,
      content: backendReply.reply,
      payload: normalizeBackendPayload(backendReply.raw, backendReply.reply),
      metadata: {
        backend_response: backendReply.raw,
        backend_source: backendReply.source,
      },
    });

  if (assistantMessageError) {
    return jsonResponse({ error: assistantMessageError.message }, 500);
  }

  await supabase
    .from("chat_sessions")
    .update({
      last_message: backendReply.reply,
      last_message_at: new Date().toISOString(),
      session_state: {
        last_backend_response: backendReply.raw,
      },
    })
    .eq("id", sessionId);

  return jsonResponse({
    reply: backendReply.reply,
    session_id: sessionId,
  });
});

async function getOrCreateSession(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  sessionId?: string,
  profile?: {
    phoneNumber: string | null;
    userName: string | null;
  },
): Promise<
  | { sessionId: string }
  | { error: string; status: number }
> {
  if (sessionId) {
    const { data, error } = await supabase
      .from("chat_sessions")
      .select("id")
      .eq("id", sessionId)
      .eq("profile_id", userId)
      .maybeSingle();

    if (error) {
      return { error: error.message, status: 500 };
    }

    if (!data) {
      return { error: "Chat session not found", status: 404 };
    }

    await supabase
      .from("chat_sessions")
      .update({
        ...(profile?.phoneNumber ? { phone_number: profile.phoneNumber } : {}),
        ...(profile?.userName ? { user_name: profile.userName } : {}),
      })
      .eq("id", data.id);

    return { sessionId: data.id };
  }

  const { data, error } = await supabase
    .from("chat_sessions")
    .insert({
      profile_id: userId,
      ...(profile?.phoneNumber ? { phone_number: profile.phoneNumber } : {}),
      ...(profile?.userName ? { user_name: profile.userName } : {}),
    })
    .select("id")
    .single();

  if (error) {
    return { error: error.message, status: 500 };
  }

  return { sessionId: data.id };
}

async function callRudoBackend(input: {
  userId: string;
  sessionId: string;
  message: string;
  clientMessageId: string | null;
  metadata: Record<string, unknown>;
}): Promise<BackendReply> {
  const backendUrl = Deno.env.get("DAWAMOM_BACKEND_URL") ?? defaultRudoBackendUrl;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  const backendApiKey = Deno.env.get("DAWAMOM_BACKEND_API_KEY");
  if (backendApiKey) {
    headers.Authorization = `Bearer ${backendApiKey}`;
  }

  try {
    const response = await fetch(backendUrl, {
      method: "POST",
      headers,
      body: JSON.stringify({
        format: "json",
        user_id: input.userId,
        session_id: input.sessionId,
        message: input.message,
        client_message_id: input.clientMessageId,
        metadata: input.metadata,
      }),
    });

    const raw = await parseBackendResponse(response);

    if (!response.ok) {
      throw new Error(`Rudo backend returned ${response.status}`);
    }

    const reply = extractReply(raw);
    if (!reply) {
      throw new Error("Rudo backend response did not include a reply");
    }

    if (!isCannedFallbackReply(reply)) {
      return { reply, raw, source: "rudo_backend" };
    }
  } catch (error) {
    console.error("Rudo backend request failed; falling back to Gemini", error);
  }

  return await callGeminiRudo(input);
}

async function callGeminiRudo(input: {
  userId: string;
  sessionId: string;
  message: string;
  clientMessageId: string | null;
  metadata: Record<string, unknown>;
}): Promise<BackendReply> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY secret is not configured and Rudo backend fallback was not usable");
  }

  const model = Deno.env.get("RUDO_GEMINI_MODEL") ?? "gemini-2.5-flash";
  const prompt = buildRudoPrompt(input.message, input.metadata);
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          topP: 0.9,
          maxOutputTokens: 900,
        },
      }),
    },
  );

  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(`Gemini Rudo fallback returned ${response.status}`);
  }

  const reply = extractGeminiText(raw);
  if (!reply) {
    throw new Error("Gemini Rudo fallback did not include a reply");
  }

  return {
    reply,
    raw,
    source: "rudo_gemini_edge",
  };
}

function buildRudoPrompt(message: string, metadata: Record<string, unknown>): string {
  const userName = stringOrNull(metadata.user_name);
  const language = stringOrNull(metadata.language) ?? "English";
  return [
    "You are Rudo, DawaMom's warm, clinically careful maternal-health assistant.",
    "Answer pregnancy, maternal health, period tracking, appointment-preparation, and cervical-cancer education questions.",
    "Use clear, simple language. Be concise but useful. Do not invent appointment records or clinical measurements.",
    "For red flags such as severe headache, heavy bleeding, severe abdominal pain, seizures, fainting, fever, reduced fetal movement, chest pain, or trouble breathing, advise urgent medical care immediately.",
    "Do not claim to diagnose. End medical guidance with a brief reminder that this does not replace a clinician's advice.",
    `Preferred language: ${language}.`,
    `Respond entirely in ${language}, using simple, natural wording. Keep medicine names, emergency numbers, and clinic names unchanged when translating them.`,
    userName ? `Patient name: ${userName}.` : "",
    "",
    `User message: ${message}`,
  ].filter(Boolean).join("\n");
}

function extractGeminiText(raw: unknown): string | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }
  const data = raw as {
    candidates?: Array<{
      content?: {
        parts?: Array<{ text?: string }>;
      };
    }>;
  };
  const text = data.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? "")
    .join("")
    .trim();
  return text || null;
}

function isCannedFallbackReply(reply: string): boolean {
  return cannedBackendReplies.has(reply.trim());
}

function normalizeBackendPayload(
  raw: unknown,
  reply: string,
): Record<string, unknown> {
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    return raw as Record<string, unknown>;
  }

  return { reply, raw };
}

async function parseBackendResponse(response: Response): Promise<unknown> {
  const contentType = response.headers.get("Content-Type") ?? "";
  if (contentType.includes("application/json")) {
    return await response.json();
  }

  return await response.text();
}

function extractReply(raw: unknown): string | null {
  if (typeof raw === "string") {
    return raw.trim() || null;
  }

  if (!raw || typeof raw !== "object") {
    return null;
  }

  const value = raw as Record<string, unknown>;
  const reply = value.reply ?? value.message ?? value.response ?? value.text;

  return typeof reply === "string" && reply.trim() ? reply.trim() : null;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}
