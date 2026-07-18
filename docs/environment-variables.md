# Environment Variables

This page intentionally uses placeholders. I do not copy real API keys, service-role keys, private keys, tokens, passwords, or private backend credentials into documentation.

## Flutter Dart Defines

| Variable | Used By | Required | Purpose |
|---|---|---|---|
| `SUPABASE_URL` | `lib/backend/supabase/supabase_config.dart` | Recommended override | Supabase project URL. |
| `SUPABASE_ANON_KEY` | `lib/backend/supabase/supabase_config.dart` | Recommended override | Supabase publishable anon key. |
| `SKIP_SPLASH` | `lib/main.dart` | Optional | Allows splash to be skipped in some local/test contexts. |
| `TTS_PROVIDER` | `lib/services/voice_service.dart` | Optional | Controls ElevenLabs vs OmniVoice-compatible TTS behavior. |
| `ELEVENLABS_EDGE_FUNCTION` | `lib/services/voice_service.dart` | Optional | Supabase function name, defaults to `elevenlabs-tts`. |
| `ELEVENLABS_VOICE_ID` | `lib/services/voice_service.dart` | Optional | Voice ID sent to TTS function. |
| `ELEVENLABS_MODEL_ID` | `lib/services/voice_service.dart` | Optional | ElevenLabs model ID. |
| `OMNIVOICE_API_URL` | `lib/services/voice_service.dart` | Optional fallback | Fallback TTS endpoint URL. |
| `OMNIVOICE_API_KEY` | `lib/services/voice_service.dart` | Optional fallback | Fallback TTS bearer token. |

Example:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
TTS_PROVIDER=elevenlabs
ELEVENLABS_EDGE_FUNCTION=elevenlabs-tts
ELEVENLABS_VOICE_ID=your_elevenlabs_voice_id
ELEVENLABS_MODEL_ID=eleven_multilingual_v2
OMNIVOICE_API_URL=your_omnivoice_tts_url
OMNIVOICE_API_KEY=your_omnivoice_api_key
```

## Supabase Edge Function Secrets

These belong in Supabase secrets, not Flutter.

### Dawa platform integration

| Secret or variable | Purpose |
| --- | --- |
| `DAWA_CLINICIAN_PATIENT_SYNC_URL` | Clinician patient receiver URL. |
| `DAWA_CLINICIAN_APPOINTMENT_URL` | Clinician appointment receiver URL. |
| `DAWA_CLINICIAN_DIRECTORY_URL` | Authoritative Clinician directory URL. |
| `DAWA_CLINICIAN_DIRECTORY_TOKEN` | Authenticates directory requests. |
| `DAWA_CLINICIAN_SYNC_SECRET` | Authenticates patient and appointment delivery. |
| `DAWA_MOM_SYNC_SECRET` | Validates appointment-status callbacks. |
| `DAWA_MOM_WORKER_SECRET` | Optional direct worker invocation credential; the schedule reads its value from Vault. |

Use environment-variable names in documentation and CI configuration. Store values in Supabase secrets/Vault only.

| Secret | Used By | Purpose |
|---|---|---|
| `SUPABASE_URL` | Edge Functions | Automatically provided by Supabase runtime in deployed functions. |
| `SUPABASE_ANON_KEY` | `rudo-chat`, `gemini-proxy`, `elevenlabs-tts` | Authenticated function Supabase client. |
| `SUPABASE_SERVICE_ROLE_KEY` | `firebase-auth-migrate-login` | Privileged password migration and auth admin update. |
| `DAWAMOM_BACKEND_URL` | `rudo-chat` | Rudo backend URL override. |
| `DAWAMOM_BACKEND_API_KEY` | `rudo-chat` | Optional backend bearer token. |
| `GEMINI_API_KEY` | `rudo-chat`, `gemini-proxy` | Gemini fallback/helper calls. |
| `RUDO_GEMINI_MODEL` | `rudo-chat` | Optional Gemini model override. |
| `ELEVENLABS_API_KEY` | `elevenlabs-tts` | ElevenLabs API access. |
| `ELEVENLABS_VOICE_ID` | `elevenlabs-tts` | Optional default voice. |
| `ELEVENLABS_MODEL_ID` | `elevenlabs-tts` | Optional default model. |

Example:

```env
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
DAWAMOM_BACKEND_URL=your_rudo_backend_url
DAWAMOM_BACKEND_API_KEY=your_backend_api_key
GEMINI_API_KEY=your_gemini_api_key
RUDO_GEMINI_MODEL=gemini-2.5-flash
ELEVENLABS_API_KEY=your_elevenlabs_api_key
ELEVENLABS_VOICE_ID=your_elevenlabs_voice_id
ELEVENLABS_MODEL_ID=eleven_multilingual_v2
```

## Python/Rudo Backend Environment

The Python backend reads these values from environment variables:

| Variable | Used By | Purpose |
|---|---|---|
| `UPSTASH_REDIS_URL` | `lib/backend/main.py`, `lib/backend/api/index.py` | Redis session/state storage. |
| `UPSTASH_REDIS_TOKEN` | Python backend | Redis auth token. |
| `WA_TOKEN` | Python backend | WhatsApp Graph API bearer token. |
| `PHONE_ID` | Python backend | WhatsApp phone ID. |
| `GEN_API` | Python backend | Generative AI key/config. |
| `OWNER_PHONE` | Python backend | Owner/admin phone number. |
| `DB_URL` | Python backend | Optional SQL database URL. |
| `PORT` | Python backend / local server | Port selection. |
| `DEBUG` | Python backend | Debug mode flag. |
| `WHATSAPP_VERIFY_TOKEN` | Python backend | Webhook verification token. |

Example:

```env
UPSTASH_REDIS_URL=your_upstash_redis_url
UPSTASH_REDIS_TOKEN=your_upstash_redis_token
WA_TOKEN=your_whatsapp_access_token
PHONE_ID=your_whatsapp_phone_id
GEN_API=your_generative_ai_key
OWNER_PHONE=your_owner_phone
DB_URL=your_database_url
PORT=8080
DEBUG=false
WHATSAPP_VERIFY_TOKEN=your_verify_token
```

## Firebase Migration Environment

Firebase service account data should not live in repo files or GitBook pages. If needed for migration scripts, use a secure local secret file or secret manager:

```env
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_SERVICE_ACCOUNT_JSON=your_secure_service_account_json
FIREBASE_AUTH_HASH_CONFIG=your_firebase_hash_config
```

## Confirmed Security Concern

The ignored local file `lib/backend/.env.txt` contains sensitive credentials in this workspace. It is ignored by `.gitignore`, but it must not be committed or synced. Rotate any credentials that may have been exposed outside the secure local environment.

## Environment Variable Gaps

- No committed `.env.example` exists.
- Supabase function secrets must be confirmed in each deployed Supabase environment.
- The current Flutter config file has default Supabase values in code. For public GitBook docs, keep examples placeholder-only.
