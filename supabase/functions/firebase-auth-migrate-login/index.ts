import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { Buffer } from "node:buffer";
import { scrypt } from "node:crypto";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type MigrationRequest = {
  email?: string;
  password?: string;
};

type LegacyCredential = {
  firebase_uid: string;
  profile_id: string | null;
  email: string;
  password_hash: string;
  salt: string;
  disabled: boolean;
  migrated_at: string | null;
};

type LegacyConfig = {
  base64_signer_key: string;
  base64_salt_separator: string;
  rounds: number;
  mem_cost: number;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let body: MigrationRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const email = body.email?.trim().toLowerCase();
  const password = body.password;
  if (!email || !password) {
    return jsonResponse({ error: "Email and password are required" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Migration function is not configured" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: credential, error: credentialError } = await supabase
    .from("firebase_auth_migration_credentials")
    .select("firebase_uid, profile_id, email, password_hash, salt, disabled, migrated_at")
    .eq("email", email)
    .maybeSingle<LegacyCredential>();

  if (credentialError) {
    return jsonResponse({ error: "Migration lookup failed" }, 500);
  }

  if (!credential || credential.disabled || !credential.profile_id) {
    return invalidLogin();
  }

  const { data: config, error: configError } = await supabase
    .from("firebase_auth_migration_config")
    .select("base64_signer_key, base64_salt_separator, rounds, mem_cost")
    .eq("id", true)
    .maybeSingle<LegacyConfig>();

  if (configError || !config) {
    return jsonResponse({ error: "Migration hash config is not available" }, 500);
  }

  let isValid = false;
  try {
    isValid = await verifyFirebasePassword(
      password,
      credential.salt,
      credential.password_hash,
      config,
    );
  } catch (error) {
    console.error("Firebase password verification failed", error);
    return jsonResponse({
      error: "Firebase password verification failed",
    }, 500);
  }

  if (!isValid) {
    return invalidLogin();
  }

  const { error: updateError } = await supabase.auth.admin.updateUserById(
    credential.profile_id,
    {
      password,
      user_metadata: {
        firebase_uid: credential.firebase_uid,
        migrated_from: "firebase",
        firebase_password_migrated: true,
      },
    },
  );

  if (updateError) {
    return jsonResponse({ error: "Could not update migrated password" }, 500);
  }

  await supabase
    .from("firebase_auth_migration_credentials")
    .update({ migrated_at: new Date().toISOString() })
    .eq("firebase_uid", credential.firebase_uid);

  return jsonResponse({ migrated: true });
});

async function verifyFirebasePassword(
  password: string,
  salt: string,
  hash: string,
  config: LegacyConfig,
): Promise<boolean> {
  const saltBytes = Buffer.concat(
    [Buffer.from(salt, "base64"), Buffer.from(config.base64_salt_separator, "base64")],
  );
  const derivedKey = await scryptAsync(
    password,
    saltBytes,
    32,
    {
      N: 2 ** config.mem_cost,
      r: config.rounds,
      p: 1,
    },
  );

  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    derivedKey,
    { name: "AES-CTR" },
    false,
    ["encrypt"],
  );
  const encrypted = await crypto.subtle.encrypt(
    {
      name: "AES-CTR",
      counter: new Uint8Array(16),
      length: 64,
    },
    cryptoKey,
    Buffer.from(config.base64_signer_key, "base64"),
  );
  const generatedHash = new Uint8Array(encrypted);
  const knownHash = Buffer.from(hash, "base64");

  return constantTimeEqual(generatedHash, knownHash);
}

function invalidLogin(): Response {
  return jsonResponse({ error: "Invalid login credentials" }, 401);
}

function scryptAsync(
  password: string,
  salt: Buffer,
  keyLength: number,
  options: { N: number; r: number; p: number },
): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scrypt(password, salt, keyLength, options, (error, derivedKey) => {
      if (error) {
        reject(error);
      } else {
        resolve(derivedKey);
      }
    });
  });
}

function constantTimeEqual(left: Uint8Array, right: Uint8Array): boolean {
  let diff = left.length ^ right.length;
  const length = Math.max(left.length, right.length);
  for (let index = 0; index < length; index += 1) {
    diff |= (left[index] ?? 0) ^ (right[index] ?? 0);
  }
  return diff === 0;
}
