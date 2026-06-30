import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type GeminiProxyRequest = {
  action?: "generate_text" | "count_tokens" | "text_from_image";
  model?: string;
  prompt?: string;
  image_base64?: string;
  mime_type?: string;
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

  const userResult = await getAuthenticatedUser(authorization);
  if ("error" in userResult) {
    return jsonResponse({ error: userResult.error }, userResult.status);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "GEMINI_API_KEY secret is not configured" }, 500);
  }

  let body: GeminiProxyRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const action = body.action ?? "generate_text";
  const model = body.model ?? "gemini-2.5-flash";
  const prompt = body.prompt?.trim();

  if (!prompt) {
    return jsonResponse({ error: "Prompt is required" }, 400);
  }

  const contents = [
    {
      parts: [
        { text: prompt },
        ...(body.image_base64
          ? [
              {
                inline_data: {
                  mime_type: body.mime_type ?? "image/jpeg",
                  data: body.image_base64,
                },
              },
            ]
          : []),
      ],
    },
  ];

  const endpointAction = action === "count_tokens" ? "countTokens" : "generateContent";
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:${endpointAction}?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents }),
    },
  );

  const raw = await response.json().catch(() => ({}));
  if (!response.ok) {
    return jsonResponse({ error: "Gemini request failed", details: raw }, response.status);
  }

  if (action === "count_tokens") {
    return jsonResponse({
      tokens: raw.totalTokens ?? raw.total_tokens ?? 0,
      raw,
    });
  }

  return jsonResponse({
    text: extractText(raw),
    raw,
  });
});

async function getAuthenticatedUser(
  authorization: string,
): Promise<{ userId: string } | { error: string; status: number }> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return { error: "Supabase function environment is not configured", status: 500 };
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return { error: "Invalid or expired session", status: 401 };
  }

  return { userId: user.id };
}

function extractText(raw: unknown): string | null {
  const response = raw as {
    candidates?: Array<{
      content?: { parts?: Array<{ text?: string }> };
    }>;
  };

  return response.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? "")
    .join("")
    .trim() || null;
}
