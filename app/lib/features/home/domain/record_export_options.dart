/// How much of the record the person chose to export.
class RecordExportOptions {
  const RecordExportOptions({
    this.patient = true,
    this.medications = true,
    this.measurements = true,
    this.appointments = true,
    this.contacts = false,
    this.detailed = false,
  });

  final bool patient;
  final bool medications;
  final bool measurements;
  final bool appointments;

  /// Names and numbers of the emergency contacts, off unless asked for.
  final bool contacts;

  /// The dose log, the unrecorded measurements and the visit papers.
  final bool detailed;

  bool get hasAnySection =>
      patient || medications || measurements || appointments;

  RecordExportOptions copyWith({
    bool? patient,
    bool? medications,
    bool? measurements,
    bool? appointments,
    bool? contacts,
    bool? detailed,
  }) => RecordExportOptions(
    patient: patient ?? this.patient,
    medications: medications ?? this.medications,
    measurements: measurements ?? this.measurements,
    appointments: appointments ?? this.appointments,
    contacts: contacts ?? this.contacts,
    detailed: detailed ?? this.detailed,
  );
}
