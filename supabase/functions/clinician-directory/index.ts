import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type DirectoryRequest = {
  action?: "list" | "availability";
  clinic_id?: string;
  clinician_id?: string;
  date?: string;
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
    return jsonResponse({ error: "Dawa Mom function environment is not configured" }, 500);
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

  let body: DirectoryRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const action = body.action ?? "list";
  if (action === "availability" && (!body.clinician_id || !body.date)) {
    return jsonResponse({ error: "clinician_id and date are required" }, 400);
  }

  const externalUrl = Deno.env.get("DAWA_CLINICIAN_DIRECTORY_URL");
  const externalToken = Deno.env.get("DAWA_CLINICIAN_DIRECTORY_TOKEN");
  if (!externalUrl || !externalToken) {
    return jsonResponse({
      code: "DIRECTORY_NOT_CONFIGURED",
      error: "The authoritative clinician directory is not connected yet",
    }, 503);
  }

  try {
    const response = await fetch(externalUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-dawa-directory-secret": externalToken,
        "x-dawa-request-user": user.id,
      },
      body: JSON.stringify({
        action,
        clinic_id: body.clinic_id ?? null,
        clinician_id: body.clinician_id ?? null,
        date: body.date ?? null,
        source: "dawa_mom",
      }),
    });

    if (!response.ok) {
      return jsonResponse({
        code: "DIRECTORY_UPSTREAM_ERROR",
        error: "The clinician directory is temporarily unavailable",
      }, response.status >= 500 ? 502 : response.status);
    }

    const payload = await response.json();
    return new Response(JSON.stringify(payload), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch {
    return jsonResponse({
      code: "DIRECTORY_UPSTREAM_UNREACHABLE",
      error: "The clinician directory is temporarily unavailable",
    }, 502);
  }
});
