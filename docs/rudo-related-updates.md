# Rudo Related Updates

## Confirmed Rudo Work

Rudo is confirmed as an assistant/chat workflow inside Dawa Mom.

Key files:

- `lib/navbar/home/home_widget.dart`
- `lib/services/voice_service.dart`
- `supabase/functions/rudo-chat/index.ts`
- `supabase/functions/rudo-chat/README.md`
- `supabase/functions/gemini-proxy/`
- `supabase/functions/elevenlabs-tts/`
- `lib/backend/main.py`
- `lib/backend/api/index.py`
- `lib/backend/training/`

## Supabase Chat Persistence

Confirmed:

- Rudo chat loads the current user's latest `chat_sessions` row.
- Rudo chat loads messages from `chat_messages`.
- Sending a message invokes the `rudo-chat` Edge Function.
- The function stores the user message and assistant reply.
- The response can update the active `session_id`.
- Chat messages include a stable `client_message_id` to reduce duplicate sends.

## Rudo Edge Function Behavior

The `rudo-chat` function:

- Requires the logged-in Supabase user's JWT.
- Stores the user message in Supabase.
- Calls a configured Rudo backend URL when available.
- Can fall back to a default backend URL.
- Can fall back to Gemini when the backend response is not usable.
- Stores assistant response content and payload in Supabase.

## Voice Mode

Confirmed:

- Rudo voice mode uses `speech_to_text`.
- TTS can go through the `elevenlabs-tts` Edge Function.
- TTS can fall back to OmniVoice-compatible HTTP configuration.
- Device TTS fallback exists through `flutter_tts`.
- Voice language mapping exists for English, Shona, Ndebele, Tonga, Bemba, Lozi, and Chinyanja/Nyanja.

Needs confirmation:

- Device-level microphone permission QA.
- ElevenLabs function secrets in every environment.
- Final voice ID/model selection.
- Whether voice should be enabled for all users.

## Rudo Backend And Training Data

The Python backend contains:

- WhatsApp webhook and message handling.
- Language detection.
- Redis/Upstash usage.
- Maternal health training data.
- Cervical cancer training data.
- Multilingual pregnancy data files.

This appears to overlap with the Rudo assistant ecosystem and not only the Flutter app.

## Rudo Design/System Relationship

No direct Rudo design-system code relationship was confirmed in this repo. The confirmed relationship is functional: Rudo chat, Rudo backend, Rudo training data, and voice assistant support.

This section is reserved for documenting any future shared design system or workflow alignment.

## Rudo Risks

- `rudo-chat` has backend fallback behavior; production should use explicit configured secrets.
- Gemini fallback requires `GEMINI_API_KEY`.
- Chat content is stored in Supabase and should be covered by privacy/security review.
- Rudo response disclaimer exists, but final health/legal wording should be reviewed.
- No automated integration tests cover Rudo chat or voice mode.
