# Gemini Proxy Edge Function

Authenticated Supabase Edge Function for Gemini helper calls. This keeps `GEMINI_API_KEY` out of Flutter.

## Required Secret

```bash
supabase secrets set GEMINI_API_KEY="<gemini-api-key>"
```

## Request

```json
{
  "action": "generate_text",
  "model": "gemini-2.5-flash",
  "prompt": "..."
}
```

Supported actions:

- `generate_text`
- `count_tokens`
- `text_from_image`
