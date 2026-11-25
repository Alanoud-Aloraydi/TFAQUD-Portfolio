import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// Everything one export needs, read before the file is written. Days and
/// clocks in it are the patient's ([clock]); instants stay UTC.
class RecordExportData {
  const RecordExportData({
    required this.options,
    required this.period,
    required this.clock,
    required this.plans,
    this.medicalFile,
    this.doses = const <DoseOccurrence>[],
    this.extraDoses = const <ExtraDose>[],
    this.readings = const <MeasurementReading>[],
    this.measurementTasks = const <MeasurementOccurrence>[],
    this.appointments = const <CareAppointment>[],
    this.visits = const <String, VisitPaper>{},
  });

  final RecordExportOptions options;
  final ExportPeriod period;
  final PatientClock clock;
  final List<MedicationPlan> plans;
  final MedicalFile? medicalFile;
  final List<DoseOccurrence> doses;

  /// «سجّل جرعة الآن»: on top of [doses], never one of them.
  final List<ExtraDose> extraDoses;
  final List<MeasurementReading> readings;
  final List<MeasurementOccurrence> measurementTasks;
  final List<CareAppointment> appointments;
  final Map<String, VisitPaper> visits;

  DateTime get today => clock.today();

  Iterable<DoseOccurrence> get missedDoses => doses.where(
    (item) => item.record == null && item.timingState == DoseTimingState.missed,
  );

  Iterable<MeasurementReading> get takenReadings =>
      readings.where((item) => item.outcome == 'read');

  int get currentMedications =>
      plans.where((item) => !item.isPreviousOn(today)).length;
}

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
