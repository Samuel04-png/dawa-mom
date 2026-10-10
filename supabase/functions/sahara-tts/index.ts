import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { encodeBase64 } from "jsr:@std/encoding/base64";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

// Sahara (Intron) TTS Generate endpoint.
// Docs: https://infer.voice.intron.io/tts/v1/generate
// - Synchronous generation; only supports text <= 4096 chars.
// - Success responses return `audio_path`, a URL to the generated file —
//   NOT audio bytes/base64 directly. We fetch that URL ourselves and
//   base64-encode it here so the client only ever deals with audio_base64.
// - Can return HTTP 503 after up to 120s if generation is still processing;
//   the response body includes a text-id for polling a separate Get TTS
//   Status endpoint. That polling endpoint isn't wired up yet (spec not
//   available at time of writing) — on 503 we fail the request but surface
//   the text-id so it can be looked up manually / wired up later.

const SAHARA_TTS_URL =
  Deno.env.get("SAHARA_TTS_URL") ?? "https://infer.voice.intron.io/tts/v1/generate";

const MAX_TEXT_LENGTH = 4096;

type TtsRequest = {
  text?: string;
  voice_language?: string;
  voice_accent?: string;
  voice_gender?: string;
  output_audio_format?: string;
};

type SaharaSuccessData = {
  audio_duration_in_seconds?: number;
  audio_path?: string;
  processing_status?: string;
  ["text-id"]?: string;
  text_id?: string;
};

type SaharaResponseBody = {
  data?: SaharaSuccessData;
  message?: string;
  status?: string;
};

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

  const saharaApiKey = Deno.env.get("SAHARA_API_KEY");
  if (!saharaApiKey) {
    return jsonResponse({ error: "SAHARA_API_KEY secret is not configured" }, 500);
  }

  let body: TtsRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const text = body.text?.trim();
  const voiceAccent = body.voice_accent?.trim();
  const voiceGender = body.voice_gender?.trim();
  const voiceLanguage = body.voice_language?.trim() || "en";
  const outputAudioFormat = body.output_audio_format?.trim() || "wav";

  if (!text) {
    return jsonResponse({ error: "text is required" }, 400);
  }
  if (text.length > MAX_TEXT_LENGTH) {
    return jsonResponse(
      { error: `text exceeds Sahara's ${MAX_TEXT_LENGTH} character limit` },
      400,
    );
  }
  if (!voiceAccent) {
    return jsonResponse({ error: "voice_accent is required" }, 400);
  }
  if (voiceGender !== "male" && voiceGender !== "female") {
    return jsonResponse({ error: "voice_gender must be 'male' or 'female'" }, 400);
  }

  let generateResponse: Response;
  try {
    generateResponse = await fetch(SAHARA_TTS_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${saharaApiKey}`,
      },
      body: JSON.stringify({
        text,
        voice_language: voiceLanguage,
        voice_accent: voiceAccent,
        voice_gender: voiceGender,
        output_audio_format: outputAudioFormat,
      }),
    });
  } catch (error) {
    return jsonResponse({
      error: `Could not reach Sahara TTS: ${error instanceof Error ? error.message : "unknown error"}`,
    }, 502);
  }

  const raw = await parseJsonSafely(generateResponse);

  if (generateResponse.status === 503) {
    const textId = raw?.data?.["text-id"] ?? raw?.data?.text_id ?? null;
    return jsonResponse({
      error: "Sahara TTS timed out while generating audio (still processing).",
      text_id: textId,
      // NOTE: polling via Sahara's "Get TTS Status" endpoint isn't implemented
      // yet — wire this up once that endpoint's request/response shape is
      // documented, then retry here instead of failing immediately.
    }, 504);
  }

  if (!generateResponse.ok) {
    const message = raw?.message ?? `Sahara TTS returned ${generateResponse.status}`;
    return jsonResponse({ error: message }, generateResponse.status);
  }

  const audioPath = raw?.data?.audio_path;
  if (!audioPath) {
    return jsonResponse({ error: "Sahara TTS response did not include audio_path" }, 502);
  }

  let audioBytes: Uint8Array;
  try {
    const audioResponse = await fetch(audioPath);
    if (!audioResponse.ok) {
      return jsonResponse(
        { error: `Could not download generated audio (${audioResponse.status})` },
        502,
      );
    }
    audioBytes = new Uint8Array(await audioResponse.arrayBuffer());
  } catch (error) {
    return jsonResponse({
      error: `Failed to fetch generated audio: ${error instanceof Error ? error.message : "unknown error"}`,
    }, 502);
  }

  return jsonResponse({
    audio_base64: encodeBase64(audioBytes),
    audio_duration_in_seconds: raw?.data?.audio_duration_in_seconds ?? null,
    output_audio_format: outputAudioFormat,
  });
});

async function parseJsonSafely(response: Response): Promise<SaharaResponseBody | null> {
  try {
    return await response.json();
  } catch {
    return null;
  }
}