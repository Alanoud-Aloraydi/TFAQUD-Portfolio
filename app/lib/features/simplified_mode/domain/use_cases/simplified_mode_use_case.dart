import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_day_loader.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_dosing.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

/// The simplified mode's reads and writes, composed from the medication,
/// measurement, appointment, circle and prayer-time features: it has no
/// endpoint of its own. Its reminders, readings and dose writes live in the
/// classes it builds on.
@lazySingleton
class SimplifiedModeUseCase extends SimplifiedDosing {
  // Not super parameters, though the analyzer offers them: `medications`
  // and `measurements` are read in the initializer list to build the
  // loader, and a super parameter cannot be. Converting only the other
  // two is not possible either, since a constructor takes super
  // parameters or a `super(...)` call, never both.
  // ignore: use_super_parameters
  SimplifiedModeUseCase(
    HomeUseCase home,
    MedicationsUseCase medications,
    MeasurementsUseCase measurements,
    AppointmentsUseCase appointments,
    CirclesUseCase circles,
    PrayerTimesUseCase prayers,
    DoseReminders reminders,
    CalendarSync calendar,
  ) : _loader = SimplifiedDayLoader(
        home,
        medications,
        measurements,
        appointments,
        circles,
        prayers,
      ),
      super(medications, measurements, reminders, calendar);

  final SimplifiedDayLoader _loader;

  /// Reads the patient's day at the instant [now]; if any dose, measurement
  /// or appointment cannot be read the whole day fails.
  Future<Result<SimplifiedDay, Failure>> loadDay(DateTime now) =>
      _loader.loadDay(now);
}
