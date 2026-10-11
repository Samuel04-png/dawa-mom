/// Release gates for workflows that require independently verified external
/// systems. Defaults deliberately favour the safe, still-useful core product.
///
/// These are build-time flags: do not enable voucher redemption in a patient
/// build until the approved clinic/service eligibility records, Clinician
/// caller, and cross-project reconciliation have all passed.
abstract final class DawaReleaseFeatures {
  /// Care Plan needs the separately reviewed `care_plan_items` migration.
  ///
  /// Release 1 deliberately ships without that schema, so this must remain
  /// opt-in. Keeping the gate at the data boundary prevents both REST and
  /// Realtime requests for a table that has not been deployed yet.
  static const carePlanEnabled = bool.fromEnvironment(
    'DAWA_CARE_PLAN_ENABLED',
    defaultValue: false,
  );

  static const voucherRedemptionEnabled = bool.fromEnvironment(
    'DAWA_VOUCHER_REDEMPTION_ENABLED',
    defaultValue: false,
  );
}
