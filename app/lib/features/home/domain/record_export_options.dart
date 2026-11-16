/// How much of the record the person chose to export.
class RecordExportOptions {
  const RecordExportOptions({
    this.patient = true,
    this.medications = true,
    this.measurements = true,
    this.appointments = true,
    this.doseLog = true,
  });

  final bool patient;
  final bool medications;
  final bool measurements;
  final bool appointments;

  /// «سجل الأدوية»: every dose of the period, one to a line, under the
  /// plans. Only read when [medications] is on.
  final bool doseLog;

  bool get hasAnySection =>
      patient || medications || measurements || appointments;

  RecordExportOptions copyWith({
    bool? patient,
    bool? medications,
    bool? measurements,
    bool? appointments,
    bool? doseLog,
  }) => RecordExportOptions(
    patient: patient ?? this.patient,
    medications: medications ?? this.medications,
    measurements: measurements ?? this.measurements,
    appointments: appointments ?? this.appointments,
    doseLog: doseLog ?? this.doseLog,
  );
}
