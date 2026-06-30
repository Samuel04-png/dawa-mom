import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type ElevenLabsTtsRequest = {
  text?: string;
  voice_id?: string;
  model_id?: string;
  language_code?: string;
};

const defaultVoiceId = "EXAVITQu4vr4xnSDxMaL";
const defaultModelId = "eleven_multilingual_v2";
const maxTextLength = 2500;

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

  const apiKey = Deno.env.get("ELEVENLABS_API_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "ELEVENLABS_API_KEY secret is not configured" }, 500);
  }

  let body: ElevenLabsTtsRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const text = body.text?.trim();
  if (!text) {
    return jsonResponse({ error: "Text is required" }, 400);
  }
  if (text.length > maxTextLength) {
    return jsonResponse({ error: `Text must be ${maxTextLength} characters or less` }, 400);
  }

  let voiceId: string;
  try {
    voiceId = sanitizePathSegment(
      body.voice_id ?? Deno.env.get("ELEVENLABS_VOICE_ID") ?? defaultVoiceId,
    );
  } catch {
    return jsonResponse({ error: "Invalid voice_id" }, 400);
  }
  const modelId = body.model_id?.trim() || Deno.env.get("ELEVENLABS_MODEL_ID") || defaultModelId;
  const languageCode = body.language_code?.trim();
  const endpoint = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;

  const elevenLabsResponse = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Accept": "audio/mpeg",
      "Content-Type": "application/json",
      "xi-api-key": apiKey,
    },
    body: JSON.stringify({
      text,
      model_id: modelId,
      ...(languageCode ? { language_code: languageCode } : {}),
      voice_settings: {
        stability: 0.45,
        similarity_boost: 0.8,
        style: 0.0,
        use_speaker_boost: true,
      },
    }),
  });

  if (!elevenLabsResponse.ok) {
    return jsonResponse({
      error: `ElevenLabs TTS failed with ${elevenLabsResponse.status}`,
      details: await safeErrorText(elevenLabsResponse),
    }, 502);
  }

  const audioBuffer = await elevenLabsResponse.arrayBuffer();
  return jsonResponse({
    audio_base64: arrayBufferToBase64(audioBuffer),
    content_type: elevenLabsResponse.headers.get("content-type") ?? "audio/mpeg",
  });
});

function sanitizePathSegment(value: string): string {
  const trimmed = value.trim();
  if (!/^[A-Za-z0-9_-]+$/.test(trimmed)) {
    throw new Error("Invalid voice_id");
  }
  return trimmed;
}

async function safeErrorText(response: Response): Promise<string> {
  try {
    return (await response.text()).slice(0, 1000);
  } catch {
    return "";
  }
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  const chunkSize = 0x8000;
  let binary = "";

  for (let index = 0; index < bytes.length; index += chunkSize) {
    const chunk = bytes.subarray(index, index + chunkSize);
    binary += String.fromCharCode(...chunk);
  }

  return btoa(binary);
}
