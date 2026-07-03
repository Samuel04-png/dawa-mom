# Language Support

## Current Status

Language support is partially confirmed.

The Flutter app currently declares only English as a supported app locale, but the Rudo voice/backend code contains support for multiple languages.

## Flutter App Locales

Confirmed in `lib/main.dart`:

```dart
supportedLocales: const [Locale('en', '')],
```

This means the Flutter UI itself is not currently confirmed as translated into multiple locales.

## Rudo Voice Language Mapping

Confirmed in `lib/services/voice_service.dart`:

- English
- Shona
- Ndebele
- Tonga
- Bemba
- Lozi
- Chinyanja / Nyanja

The voice service maps these to speech recognition and TTS locale/language codes.

## Rudo Chat Language Metadata

Confirmed in `supabase/functions/rudo-chat/index.ts`:

- The Rudo prompt reads `metadata.language` when present.
- If no language metadata is found, it defaults to English.

Needs confirmation:

- The Flutter chat request currently sends phone number, user name, and source metadata. I did not confirm a language value being sent in the request body.

## Backend Training Language Support

Confirmed in `lib/backend/training/` and Python backend code:

- Pregnancy data exists for English plus Shona, Ndebele, Tonga, Chinyanja, Bemba, and Lozi.
- Backend instructions mention responding in the user's chosen language.
- Python backend has language detection and language-state logic.

## Translation Files

Not confirmed.

I did not find ARB files, JSON translation files, or a Flutter localization class for translated UI strings.

## Language Switching

Not confirmed for the Flutter UI.

There is no confirmed in-app language picker or persisted language setting in the Flutter UI.

## How To Add A New UI Language

Future implementation should include:

1. Add Flutter localization files and generation config.
2. Add translated strings for all UI text.
3. Add the locale to `supportedLocales`.
4. Add a language selector or infer language from device settings.
5. Store the selected language in user profile or local settings.
6. Send selected language into Rudo chat metadata.
7. Extend voice language mapping if voice is supported for that language.
8. Test text overflow across all screens.

## Known Gaps

- UI translations are not implemented.
- Rudo voice supports language mappings, but full end-to-end language selection needs confirmation.
- Clinical/health content translations should be reviewed before release.
