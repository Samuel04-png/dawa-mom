# Known Issues

## Critical

| Issue | Evidence | Risk | Status |
|---|---|---|---|
| Local ignored credentials file exists | `lib/backend/.env.txt` exists locally and is ignored by `.gitignore`. | If copied or committed, it can expose WhatsApp and Firebase credentials. | Critical local security issue. Do not sync. Rotate if exposed. |

## High

| Issue | Evidence | Risk | Status |
|---|---|---|---|
| Persisted `motherRef` needs patient isolation review | `lib/app_state.dart` persists `ff_motherRef`; many screens use `FFAppState().motherRef`. | Stale or wrong references could break patient isolation after auth changes/migration. | Needs review. |
| RLS needs live role testing | SQL policies exist for patients/doctors/admins. | Policies may pass syntax but fail real workflow expectations. | Needs verification in Supabase. |
| Firebase password migration bridge needs live testing | Code and SQL exist, but function depends on service role and hash config. | Migrated users may fail login if config/import is wrong. | Needs live confirmation. |
| Health interpretation needs clinical review | BP and other rules are hardcoded. | Incorrect medical labels could mislead users. | Needs clinical review. |

## Medium

| Issue | Evidence | Risk | Status |
|---|---|---|---|
| No standalone BP monitor found | BP exists in encounter results and struct, but no monitor page/input flow was found. | User expectations may not match implementation. | Needs confirmation. |
| No screenshots committed | Asset folders exist, but no app screenshots found. | GitBook will lack real visuals until captures are added. | Needs capture. |
| Offline mode not implemented | Only SharedPreferences/session persistence confirmed. | Users may expect offline access that does not exist. | Not confirmed in codebase. |
| No `.env.example` | Only ignored local `.env.txt` exists. | New developers may not know safe config names. | Needs safe example file later. |
| Limited automated tests | Only two test files found. | Regressions in auth, appointments, RLS, Rudo, and health logic may be missed. | Needs coverage. |
| Rudo backend fallback behavior | `rudo-chat` has default backend fallback and Gemini fallback. | Production behavior may be unclear if secrets are missing. | Needs environment confirmation. |
| Doctor/admin UI not confirmed | Schema supports roles, visible app flow is mostly mother-facing. | Team may assume UI exists because backend roles exist. | Needs confirmation. |

## Low

| Issue | Evidence | Risk | Status |
|---|---|---|---|
| Typo in health UI logic | `Potentital` appears in encounter details. | Small UX/professional polish issue. | Needs fix later. |
| Legacy naming remains | Firestore helper names remain. | Confusing for new developers. | Documented compatibility behavior. |
| Misspelled generated collection name | `weeks_of_pregenancy` remains in compatibility mapping. | Confusing but likely necessary for generated code. | Leave unless refactor is planned. |
| No storage bucket docs | No Supabase storage migrations found. | Storage expectations may be unclear. | Not confirmed. |

## Security Notes

- Do not document or expose service role keys.
- Do not copy local `.env.txt` values into GitBook.
- Keep Gemini, ElevenLabs, WhatsApp, Firebase service account, and backend tokens in secret managers.
- Treat Supabase RLS as a release-blocking verification item.
