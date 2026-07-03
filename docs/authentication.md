# Authentication

Dawa Mom currently uses Supabase Auth as the active authentication layer.

## Login Flow

Confirmed flow:

1. The Login screen collects email and password.
2. `authManager.signInWithEmail()` is called.
3. `SupabaseAuthManager` attempts Supabase email/password sign-in.
4. On invalid credentials only, it attempts Firebase password migration through `firebase-auth-migrate-login`.
5. If migration succeeds, the app signs in again with Supabase.
6. The user is routed to Home.

Key files:

- `lib/auth/login/login_widget.dart`
- `lib/auth/supabase_auth/supabase_auth_manager.dart`
- `supabase/functions/firebase-auth-migrate-login/index.ts`

## Signup Flow

Confirmed flow:

1. The Register screen collects email, password, and confirm password.
2. The app calls `createAccountWithEmail()`.
3. Supabase Auth `signUp` receives `requested_role: patient`.
4. The app updates the profile row with `role: patient` and `requested_role: patient`.
5. The app creates a new mother row.
6. The user is routed to profile completion in `CreateAccountWidget`.
7. Profile completion updates mother details.

Key files:

- `lib/auth/register/register_widget.dart`
- `lib/auth/create_account/create_account_widget.dart`
- `lib/backend/backend.dart`
- `lib/backend/schema/mother_record.dart`

## Session Persistence

Confirmed behavior:

- `supabase_flutter` manages auth session state.
- `initSupabase()` refreshes a persisted session on startup.
- If refresh fails, the app signs out locally.
- `SupabaseDatabase.runWithFreshSession()` refreshes sessions before database work when expiry is close.
- Expired JWT errors trigger a forced refresh and retry.

Key files:

- `lib/backend/supabase/supabase_config.dart`
- `lib/backend/supabase/supabase_database.dart`
- `lib/auth/supabase_auth/supabase_user_provider.dart`
- `lib/auth/supabase_auth/auth_util.dart`

## Password Reset

Confirmed behavior:

- Forgot Password screen calls `authManager.resetPassword`.
- The auth manager calls Supabase `resetPasswordForEmail`.
- If the SDK request times out, it retries through the Supabase recover endpoint.
- The user sees a generic message when a reset request is sent.

Key files:

- `lib/auth/forgot_password/forgot_password_widget.dart`
- `lib/auth/supabase_auth/supabase_auth_manager.dart`

## Role-Based Access

The database schema confirms roles:

- `patient`
- `doctor`
- `admin`

Role behavior in migrations:

- New auth users start as `patient`.
- Signup can request `doctor`, but role promotion requires admin/manual approval.
- Admin role cannot be self-requested.
- Patients can access their own mother/profile data and appointment fields.
- Doctors can access assigned mother/encounter data.
- Admins can read/manage selected app data.

Needs confirmation:

- I did not find a complete doctor/admin UI flow in the Flutter app.
- The actual admin approval process is documented as manual and still needs operational confirmation.

## Firebase Legacy Auth

Firebase legacy auth exists only as a migration bridge:

- Flutter does not use Firebase auth packages.
- Invalid Supabase login can invoke `firebase-auth-migrate-login`.
- The Edge Function checks stored Firebase password hash material and updates Supabase password on success.

## Offline Login Behavior

Not confirmed. The app can have a persisted Supabase session locally, but I did not find a designed offline login mode. If the session cannot refresh, startup code signs out locally.

## Authentication Risks

- The Firebase password migration Edge Function needs service-role access and must be protected operationally.
- The login fallback should be tested with migrated and non-migrated users.
- Role promotion should happen through secure admin/service-role paths only.
- Persisted `motherRef` should be checked after auth transitions so users do not retain stale mother references.
