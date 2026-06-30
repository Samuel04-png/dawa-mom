# elevenlabs-tts

Authenticated Supabase Edge Function that proxies Rudo voice replies through ElevenLabs without exposing the ElevenLabs API key in Flutter.

## Secrets

Set the API key as a Supabase secret:

```powershell
supabase secrets set ELEVENLABS_API_KEY="<elevenlabs-api-key>" --project-ref himbfndvsuwiudtzjojh
```

Optional defaults:

```powershell
supabase secrets set ELEVENLABS_VOICE_ID="EXAVITQu4vr4xnSDxMaL" ELEVENLABS_MODEL_ID="eleven_multilingual_v2" --project-ref himbfndvsuwiudtzjojh
```

## Deploy

```powershell
supabase functions deploy elevenlabs-tts --project-ref himbfndvsuwiudtzjojh
```

The Flutter app calls this function through `Supabase.instance.client.functions.invoke`, so the user must be signed in and have a valid Supabase session.
