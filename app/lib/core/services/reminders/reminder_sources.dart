import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';

/// Where the tasks are read from; the measurements and the visits are
/// absent in tests of the doses alone.
class ReminderSources {
  const ReminderSources(
    this.medications, {
    this.measurements,
    this.appointments,
  });

  final MedicationsUseCase medications;
  final MeasurementsUseCase? measurements;
  final AppointmentsUseCase? appointments;
}
