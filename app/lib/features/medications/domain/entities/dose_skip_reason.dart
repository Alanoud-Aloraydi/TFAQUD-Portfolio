/// Why a dose was not taken, as offered on the skip sheet.
enum DoseSkipReason {
  forgotten,
  unavailable,
  sideEffects,
  patientRefused,
  other;

  /// The API's word for the reason.
  String get apiValue => switch (this) {
    sideEffects => 'side_effects',
    patientRefused => 'patient_refused',
    _ => name,
  };
}
