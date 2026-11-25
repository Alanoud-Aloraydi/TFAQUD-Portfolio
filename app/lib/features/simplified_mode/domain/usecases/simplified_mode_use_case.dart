import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/prayer_times/domain/usecases/prayer_times_use_case.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_reminders.dart';
import 'package:app/features/simplified_mode/domain/usecases/result_attempt.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_reminding.dart';
import 'package:multiple_result/multiple_result.dart';

/// The simplified mode's reads and writes, composed from the medication,
/// measurement, appointment, circle and prayer-time features: it has no
/// endpoint of its own. Its reminders, readings and dose writes live in the
/// classes it builds on.
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
    SimplifiedReminders reminders,
  ) : _appointments = appointments,
      _loader = SimplifiedDayLoader(
        home,
        medications,
        measurements,
        appointments,
        circles,
        prayers,
      ),
      super(medications, measurements, reminders);

  final AppointmentsUseCase _appointments;
  final SimplifiedDayLoader _loader;

  /// «حضرت»: the patient's own visit is marked attended, the record the
  /// family writes with the same button in the detailed mode.
  Future<Result<CareAppointment, Failure>> attendAppointment(
    String circleId,
    CareAppointment visit,
  ) => attemptResult(
    () => _appointments.setStatus(circleId, visit, AppointmentStatus.completed),
  );

  /// Reads the patient's day at the instant [now]; if any dose, measurement
  /// or appointment cannot be read the whole day fails.
  Future<Result<SimplifiedDay, Failure>> loadDay(DateTime now) =>
      _loader.loadDay(now);
}

/// The patient's own circle in [account], if it has one.
///
/// A simplified account is always the patient. Never fall back to a circle
/// they merely manage: every task, family member and medical fact on this
/// mode must belong to the person's own circle.
CareCircleSummary? simplifiedPatientCircle(HomeEntity account) =>
    account.circles.where((item) => item.isPatient).firstOrNull;

/// The family members the patient can phone: not the patient, not the
/// person using the phone, and with a number on file.
List<CircleMember> simplifiedFamily(CircleOverview? overview) => <CircleMember>[
  for (final CircleMember member in overview?.members ?? const <CircleMember>[])
    if (!member.isPatient && !member.isYou && member.phoneNumber != null)
      member,
];

/// Each medicine's reason, by plan id, for the plans that name one.
Map<String, String> simplifiedReasons(List<MedicationPlan>? plans) =>
    <String, String>{
      for (final MedicationPlan plan in plans ?? const <MedicationPlan>[])
        if (plan.version.reason case final String reason
            when reason.trim().isNotEmpty)
          plan.id: reason.trim(),
    };

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
