# Code Snippets

This page includes selected snippets that explain important implementation points. I intentionally avoid copying any real secrets.

## Supabase Client Initialization

**File:** `lib/backend/supabase/supabase_config.dart`

**Purpose:** Explains how the app connects to Supabase. Values are redacted with placeholders.

```dart
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'your_supabase_url',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your_supabase_anon_key',
);

Future<void> initSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError('Supabase URL and anon key must be configured.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  await _refreshPersistedSession();
}
```

**Notes:**

- The actual file contains production defaults. Do not copy real keys into GitBook.
- Prefer Dart defines for staging/local overrides.

## Session Refresh Wrapper

**File:** `lib/backend/supabase/supabase_database.dart`

**Purpose:** Keeps database actions from failing unnecessarily when a Supabase JWT is close to expiry.

```dart
Future<T> runWithFreshSession<T>(Future<T> Function() action) async {
  await _refreshSessionIfExpiringSoon();
  try {
    return await action();
  } catch (error) {
    if (!_isExpiredJwtError(error)) {
      rethrow;
    }
    await _forceRefreshSession();
    return action();
  }
}
```

**Notes:**

- This is used by compatibility reads/writes and period tracker service calls.
- If refresh fails, the app signs out locally.

## Supabase Auth Login With Firebase Migration Fallback

**File:** `lib/auth/supabase_auth/supabase_auth_manager.dart`

**Purpose:** Handles normal Supabase login and legacy Firebase password migration.

```dart
Future<AuthResponse> _signInWithFirebaseMigrationFallback(
  String email,
  String password,
) async {
  try {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  } on AuthException catch (e) {
    if (!_isInvalidLogin(e)) {
      rethrow;
    }

    final migrated = await _tryMigrateFirebasePassword(email, password);
    if (!migrated) {
      rethrow;
    }

    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```

**Notes:**

- The fallback only runs after invalid Supabase credentials.
- The Edge Function must be configured securely with service-role access.

## Mother Profile Creation After Signup

**File:** `lib/auth/register/register_widget.dart`

**Purpose:** Creates/updates patient profile metadata and creates a linked mother row.

```dart
await SupabaseDatabase.instance.client
    .from('profiles')
    .update({
  'email': email,
  'role': 'patient',
  'requested_role': 'patient',
  'updated_at': DateTime.now().toUtc().toIso8601String(),
}).eq('id', newUserId);

await MotherRecord.collection.doc().set(createMotherRecordData(
  userId: UserRecord.collection.doc(newUserId),
));
```

**Notes:**

- This snippet is simplified to remove controller references.
- Profile/mother creation should be tested with RLS enabled.

## Mother Profile Completion

**File:** `lib/auth/create_account/create_account_widget.dart`

**Purpose:** Updates mother details after registration.

```dart
await createAccountMotherRecord!.reference.update(createMotherRecordData(
  dateOfBirth: datePicked,
  occupation: occupation,
  address: address,
  name: name,
  phoneNumber: phoneNumber,
  motherId: createAccountMotherRecord.reference.id,
));
```

**Notes:**

- The actual code reads values from Flutter text controllers.
- This flow depends on finding the current user's mother record.

## Supabase Compatibility Collection Mapping

**File:** `lib/backend/supabase/supabase_database.dart`

**Purpose:** Maps legacy FlutterFlow collection names to Supabase table names.

```dart
const _collectionMappings = {
  'user': 'profiles',
  'mother': 'mothers',
  'doctor': 'doctors',
  'clinic': 'clinics',
  'first_encounter': 'first_encounters',
  'encounter': 'encounters',
  'parity': 'parities',
  'weeks_of_pregenancy': 'pregnancy_weeks',
};
```

**Notes:**

- The misspelling `weeks_of_pregenancy` is preserved for generated-code compatibility.
- This is why old record classes can keep working after the Supabase migration.

## Period Tracker Save

**File:** `lib/backend/period_tracker_service.dart`

**Purpose:** Saves period tracker settings for the current Supabase user.

```dart
await SupabaseDatabase.instance.runWithFreshSession(
  () => _client.from('period_tracker_settings').upsert({
    'profile_id': profileId,
    'average_cycle_length': averageCycleLength,
    'period_length': periodLength,
    'is_regular': isRegular,
    'last_period_start':
        lastPeriodStart != null ? formatDateId(lastPeriodStart) : null,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  }, onConflict: 'profile_id'),
);
```

**Notes:**

- User ownership is based on `Supabase.instance.client.auth.currentUser?.id`.
- RLS must allow the logged-in user to write their own tracker data.

## Rudo Chat Send

**File:** `lib/navbar/home/home_widget.dart`

**Purpose:** Sends a chat message through the Supabase Edge Function.

```dart
final response = await _database.client.functions.invoke(
  'rudo-chat',
  body: {
    'message': trimmedMessage,
    if (_sessionId != null) 'session_id': _sessionId,
    'client_message_id': clientMessageId,
    'metadata': {
      'phone_number': widget.userPhoneNumber,
      'user_name': widget.userName,
      'source': 'flutter',
    },
  },
).timeout(const Duration(seconds: 45));
```

**Notes:**

- `client_message_id` helps prevent duplicate persisted messages.
- Rudo responses are stored in Supabase.

## Voice Language Mapping

**File:** `lib/services/voice_service.dart`

**Purpose:** Maps language names to TTS/STT locale codes.

```dart
String _localeForLanguage(String? language) {
  final value = (language ?? '').toLowerCase();
  return switch (value) {
    'shona' => 'sn_ZW',
    'ndebele' => 'nd_ZW',
    'tonga' => 'toi_ZM',
    'bemba' => 'bem_ZM',
    'lozi' => 'loz_ZM',
    'chinyanja' || 'nyanja' => 'ny_ZM',
    _ => 'en_US',
  };
}
```

**Notes:**

- Flutter UI localization is currently only English.
- Voice support is broader than UI translation support.

## Blood Pressure Interpretation

**File:** `lib/flutter_flow/custom_functions.dart`

**Purpose:** Classifies a `systolic/diastolic` string.

```dart
String? bloodPressureConversion(String bp) {
  try {
    var parts = bp.split('/');
    if (parts.length != 2) throw FormatException();

    int systolic = int.parse(parts[0].trim());
    int diastolic = int.parse(parts[1].trim());

    if (systolic >= 160 || diastolic >= 90) {
      return 'Severely High';
    } else if ((systolic >= 140 && systolic < 160) ||
        (diastolic >= 80 && diastolic < 90)) {
      return 'Moderately High';
    } else if ((systolic >= 90 && systolic < 120) ||
        (diastolic >= 60 && diastolic < 80)) {
      return 'Normal';
    } else if (systolic < 90 && diastolic < 60) {
      return 'Low';
    } else {
      return 'Out of Classification';
    }
  } catch (e) {
    return 'Invalid Input';
  }
}
```

**Notes:**

- Needs clinical review before being used as medical guidance.
- No age/chronic disease adjustment is currently wired into this helper.

## Encounter Result Display

**File:** `lib/navbar/appointments/encounter_details/encounter_details_widget.dart`

**Purpose:** Displays interpreted BP result from a completed encounter.

```dart
Text(
  valueOrDefault<String>(
    functions.bloodPressureConversion(
      encounterDetailsEncounterRecord.bp,
    ),
    'Normal',
  ),
)
```

**Notes:**

- This is display-only in the confirmed code.
- Standalone BP input/save was not confirmed.

## Persisted Mother Reference

**File:** `lib/app_state.dart`

**Purpose:** Persists the selected mother record reference locally.

```dart
DocumentReference? _motherRef;
DocumentReference? get motherRef => _motherRef;
set motherRef(DocumentReference? value) {
  _motherRef = value;
  value != null
      ? prefs.setString('ff_motherRef', value.path)
      : prefs.remove('ff_motherRef');
}
```

**Notes:**

- This is a migration review point.
- The app should resolve the current user's mother row safely after login.

## Bottom Navigation

**File:** `lib/main.dart`

**Purpose:** Defines the primary mother-facing tabs.

```dart
final tabs = {
  'Home': HomeWidget(),
  'Appointments': EncountersWidget(),
  'PeriodTracker': PeriodTrackerWidget(),
};
```

**Notes:**

- Period Tracker is a tab, not a standalone GoRouter route in `nav.dart`.
- Appointments route into `EncountersWidget`.

## Theme Token Example

**File:** `lib/flutter_flow/flutter_flow_theme.dart`

**Purpose:** Centralized theme color tokens.

```dart
class LightModeTheme extends FlutterFlowTheme {
  late Color primary = const Color(0xFF1945CD);
  late Color secondary = const Color(0xFF35EB1D);
  late Color primaryBackground = const Color(0xFFF1F4F8);
  late Color secondaryBackground = const Color(0xFFFFFFFF);
}
```

**Notes:**

- Poppins is the main font family.
- Theme mode is persisted through `SharedPreferences`.
