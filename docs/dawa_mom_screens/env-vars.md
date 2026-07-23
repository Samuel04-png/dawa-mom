# Dawa Mom redesign environment variables

The redesign adds no client secret and requires no new environment variable.
The additive learning, preference, reward, notification-read, and appointment
reminder persistence uses the existing authenticated Supabase session.

## Flutter build-time values

| Name | Purpose | Secret? |
|---|---|---|
| `SUPABASE_URL` | Supabase project API URL | No |
| `SUPABASE_ANON_KEY` | Public/anonymous project key used with RLS | No |
| `TTS_PROVIDER` | Selects the existing audio/TTS provider integration | No |
| `ELEVENLABS_VOICE_ID` | Selects an existing server-side voice | No |

No `SUPABASE_SERVICE_ROLE_KEY`, model provider key, worker token, or integration
secret belongs in Flutter.

## Existing server-only values used by retained flows

These names are documented for deployment completeness; the redesign does not
write or reveal their values.

| Name | Existing server use |
|---|---|
| `SUPABASE_URL` | Edge Function project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-only queue and trusted lookup work |
| `GEMINI_API_KEY` | Existing Gemini proxy and Rudo fallback |
| `RUDO_GEMINI_MODEL` | Existing Rudo model selection |
| `DAWAMOM_BACKEND_URL` | Existing Rudo backend |
| `DAWAMOM_BACKEND_API_KEY` | Existing Rudo backend authentication |
| `ELEVENLABS_API_KEY` | Existing server-side TTS |
| `ELEVENLABS_VOICE_ID` | Existing voice selection |
| `ELEVENLABS_MODEL_ID` | Existing ElevenLabs model selection |
| `TTS_PROVIDER` | Existing TTS provider selection |
| `OMNIVOICE_API_KEY` | Existing alternative TTS provider |
| `OMNIVOICE_API_URL` | Existing alternative TTS endpoint |
| `RESEND_API_KEY` | Existing appointment email delivery |
| `APPOINTMENT_EMAIL_FROM` | Existing appointment sender identity |
| `APPOINTMENT_EMAIL_WORKER_SECRET` | Existing email worker authentication |
| `APPOINTMENT_EMAIL_MAX_ATTEMPTS` | Existing queue retry limit |
| `DAWA_CLINICIAN_DIRECTORY_URL` | Existing server-to-server clinician directory |
| `DAWA_CLINICIAN_DIRECTORY_TOKEN` | Existing directory authentication |
| `DAWA_CLINICIAN_EMAIL_RESOLVER_URL` | Existing clinician email resolver |
| `DAWA_CLINICIAN_EMAIL_RESOLVER_TOKEN` | Existing resolver authentication |
| `DAWA_CLINICIAN_APPOINTMENT_URL` | Existing appointment integration endpoint |
| `DAWA_CLINICIAN_PATIENT_SYNC_URL` | Existing patient sync endpoint |
| `DAWA_CLINICIAN_SYNC_SECRET` | Existing clinician integration authentication |
| `DAWA_MOM_SYNC_SECRET` | Existing incoming Dawa Mom sync authentication |
| `DAWA_MOM_WORKER_SECRET` | Existing durable integration worker authentication |

## Existing Vault value

`dawa_mom_worker_secret` is the existing Supabase Vault name used by the
scheduled Dawa platform outbox worker. It remains server-side.
