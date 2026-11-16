/// Why a reading was skipped.
enum MeasurementSkipReason {
  forgotten,
  equipmentUnavailable,
  patientRefused,
  unwell,
  other;

  String get apiValue => switch (this) {
    equipmentUnavailable => 'equipment_unavailable',
    patientRefused => 'patient_refused',
    _ => name,
  };
}
