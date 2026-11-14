import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
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
