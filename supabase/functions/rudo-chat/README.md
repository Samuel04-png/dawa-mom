# Rudo Chat Edge Function

This Edge Function is a Supabase-side proxy for Rudo chat.

It is designed for the phased migration:

- Flutter calls this function with the logged-in Supabase user's JWT.
- The function stores the user message in Supabase.
- The function calls the existing production Rudo/backend endpoint using secrets.
- The function stores the assistant reply in Supabase.
- The production backend can keep Redis/live chat state at the same time.
- Chat payloads remain JSON-shaped so current Upstash Redis session/message data can be migrated into Supabase.
- Chat history is readable by the patient, doctors assigned to that patient's appointments, and admins.

## Backend Configuration

The function uses `DAWAMOM_BACKEND_URL` when it is configured. If the secret is
not available, it tries the current production backend URL:

```text
https://rudo-mobile-app.vercel.app/api/chat
```

That endpoint currently returns a canned greeting for unrelated questions. To
avoid showing fallback/demo data in the app, `rudo-chat` detects that canned
reply and falls back to Gemini inside the Supabase Edge Function.

Set the secret when the Supabase account has project secret permissions:

Set these after the Supabase project exists:

```bash
supabase secrets set DAWAMOM_BACKEND_URL="https://your-production-backend.example/rudo"
```

Optional backend bearer token:

```bash
supabase secrets set DAWAMOM_BACKEND_API_KEY="<new-backend-token>"
```

Gemini fallback secret:

```bash
supabase secrets set GEMINI_API_KEY="<gemini-api-key>" --project-ref himbfndvsuwiudtzjojh
```

Do not put Gemini keys in Flutter.

## Request Body

```json
{
  "message": "hello",
  "session_id": "optional-existing-session-uuid",
  "client_message_id": "stable-client-generated-id",
  "metadata": {
    "phone_number": "+260...",
    "user_name": "Patient Name",
    "source": "flutter"
  }
}
```

`client_message_id` should be generated once per outbound user message by Flutter. Reusing the same value on retries prevents the double-message issue from creating duplicate chat rows or duplicate backend calls.

The Edge Function forwards JSON to the backend and includes `"format": "json"` in the backend request. Supabase stores:

- display text in `chat_messages.content`
- full message JSON in `chat_messages.payload`
- migrated/live session JSON in `chat_sessions.session_state`

## Response Body

```json
{
  "reply": "assistant reply",
  "session_id": "chat-session-uuid"
}
```
