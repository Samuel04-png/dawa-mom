/// Release gates for workflows that require independently verified external
/// systems. Defaults deliberately favour the safe, still-useful core product.
///
/// These are build-time flags: do not enable voucher redemption in a patient
/// build until the approved clinic/service eligibility records, Clinician
/// caller, and cross-project reconciliation have all passed.
abstract final class DawaReleaseFeatures {
  static const voucherRedemptionEnabled = bool.fromEnvironment(
    'DAWA_VOUCHER_REDEMPTION_ENABLED',
    defaultValue: false,
  );
}
