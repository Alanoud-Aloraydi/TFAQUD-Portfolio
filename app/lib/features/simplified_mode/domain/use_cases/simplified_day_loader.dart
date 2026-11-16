import 'package:app/core/errors/failure.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/use_cases/result_attempt.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_day_decor.dart';
import 'package:multiple_result/multiple_result.dart';

/// Reads the patient's whole day from the features that hold its parts.
class SimplifiedDayLoader {
  SimplifiedDayLoader(
    this._home,
    this._medications,
    this._measurements,
    this._appointments,
    this._circles,
    this._prayers,
  );

  final HomeUseCase _home;
  final MedicationsUseCase _medications;
  final MeasurementsUseCase _measurements;
  final AppointmentsUseCase _appointments;
  final CirclesUseCase _circles;
  final PrayerTimesUseCase _prayers;

  /// Reads the patient's day at the instant [now]: the day of the patient's
  /// own zone, wherever this phone is.
  ///
  /// Doses, measurements and appointments decide what the patient is told
  /// («أنجزت كل شيء»), so if any of them cannot be read the whole day fails
  /// rather than showing an incomplete day as done. The family row, the
  /// medicines' reasons and the prayer times only decorate the screen, so
  /// each of those degrades to nothing on its own.
  Future<Result<SimplifiedDay, Failure>> loadDay(DateTime now) async {
    final Result<HomeEntity, Failure> home = await _home.getHome();
    final HomeEntity? account = home.tryGetSuccess();
    if (account == null) return Error(home.tryGetError()!);
    final CareCircleSummary? circle = simplifiedPatientCircle(account);
    if (circle == null) return const Error(EmptyDataFailure());

    final DateTime today = circle.clock.today(now);
    final DateTime tomorrow = addDays(today, 1);
    final (doses, measurements, appointments) = await (
      _medications.getOccurrences(circle.id, today, tomorrow),
      attemptResult(() => _measurements.occurrences(circle.id, today, today)),
      attemptResult(() => _appointments.appointments(circle.id)),
    ).wait;
    final Failure? failure =
        doses.tryGetError() ??
        measurements.tryGetError() ??
        appointments.tryGetError();
    if (failure != null) return Error(failure);

    final (overview, plans, prayers) = await (
      _circles.getCircleOverview(circle.id),
      _medications.getPlans(circle.id),
      _prayers.getToday(circle.id),
    ).wait;

    return Success(
      SimplifiedDay(
        circleId: circle.id,
        circleName: circle.name,
        accountId: account.accountId,
        isPatient: circle.isPatient,
        displayName: account.displayName,
        avatarCode: account.avatarCode,
        timeZone: circle.timeZone,
        doses: doses.tryGetSuccess()!,
        measurements: measurements.tryGetSuccess()!,
        appointments: appointments.tryGetSuccess()!,
        family: simplifiedFamily(overview.tryGetSuccess()),
        reasons: simplifiedReasons(plans.tryGetSuccess()),
        prayers: prayers.tryGetSuccess(),
        latitude: circle.latitude,
        longitude: circle.longitude,
      ),
    );
  }
}
