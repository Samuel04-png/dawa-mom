# Blood Pressure Monitor

## Current Status

Partially done.

I confirmed blood pressure support as part of completed encounter results. I did not find a standalone patient-facing blood pressure monitor screen where a mother enters systolic, diastolic, age, chronic disease input, receives a recommendation, and saves a BP reading outside an encounter.

## Where Blood Pressure Appears

Confirmed:

- `encounters.bp` exists in the Supabase schema as a text field.
- `EncounterRecord.bp` exposes that value to Flutter.
- `EncounterDetailsWidget` displays an interpreted blood pressure result.
- `bloodPressureConversion()` parses and classifies a string like `120/80`.
- `BloodPressureStruct` exists with `systolic` and `diastolic`, but I did not find active usage as a primary BP monitor workflow.

Key files:

- `supabase/migrations/202605040001_initial_schema.sql`
- `lib/backend/schema/encounter_record.dart`
- `lib/backend/schema/structs/blood_pressure_struct.dart`
- `lib/flutter_flow/custom_functions.dart`
- `lib/navbar/appointments/encounter_details/encounter_details_widget.dart`

## Inputs Collected

Confirmed encounter result field:

- `bp`: text, expected format appears to be `systolic/diastolic`.

Confirmed struct fields:

- `systolic`
- `diastolic`

Needs confirmation:

- A user-facing systolic input field.
- A user-facing diastolic input field.
- Age input attached to BP interpretation.
- Chronic disease input attached to BP interpretation.
- Patient-entered result saving.

## Chronic Disease Context

Chronic disease fields exist in first encounter records:

- `diabetes_mellitus`
- `hypertension`
- `cardiac_disease`
- `epilepsy`
- `asthma`
- `tb`
- `sickle_cell`

These are not currently wired into `bloodPressureConversion()`.

## Blood Pressure Struct Snippet

**File:** `lib/backend/schema/structs/blood_pressure_struct.dart`

**Purpose:** Structured systolic/diastolic support exists, but active BP monitor usage was not confirmed.

```dart
class BloodPressureStruct extends FFSupabaseStruct {
  BloodPressureStruct({
    int? systolic,
    int? diastolic,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _systolic = systolic,
        _diastolic = diastolic,
        super(firestoreUtilData);

  int? _systolic;
  int get systolic => _systolic ?? 0;

  int? _diastolic;
  int get diastolic => _diastolic ?? 0;
}
```

## Interpretation Logic Snippet

**File:** `lib/flutter_flow/custom_functions.dart`

**Purpose:** Converts a BP string into a simple label.

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

## Result Display Snippet

**File:** `lib/navbar/appointments/encounter_details/encounter_details_widget.dart`

**Purpose:** Displays the interpreted result on a completed encounter detail page.

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

## Result Save Logic

Not confirmed for a standalone BP monitor.

Blood pressure can exist in the `encounters` table and `EncounterRecord`, but I did not find a mother-facing BP save action that writes systolic/diastolic or a BP result from a monitor page. Appointment booking creates `encounters` records for scheduling, but it does not save BP.

## Risk Categories Confirmed

| Category | Rule |
|---|---|
| `Severely High` | Systolic >= 160 or diastolic >= 90 |
| `Moderately High` | Systolic 140-159 or diastolic 80-89 |
| `Normal` | Systolic 90-119 or diastolic 60-79 |
| `Low` | Systolic < 90 and diastolic < 60 |
| `Out of Classification` | Parsed but does not match the above ranges |
| `Invalid Input` | Parse failure or wrong format |

## Clinical Review Needed

This logic is basic and should not be treated as clinical-grade. Before using it for medical guidance, a clinician should review:

- Pregnancy-specific BP thresholds.
- Hypertensive emergency handling.
- Age-based and chronic disease adjustments.
- Whether `or` conditions should be stricter for normal ranges.
- How to handle missing, zero, or malformed values.
- When the app should tell users to seek care.

## Recommended Next Step

If the BP monitor is meant to be a full feature, I recommend adding:

- Dedicated BP reading table.
- Systolic and diastolic numeric inputs.
- Age input or calculated age from mother profile.
- Chronic disease context from first encounter.
- Clear emergency guidance.
- Clinically reviewed interpretation rules.
- Supabase save/read history.
- Manual QA and unit tests.
