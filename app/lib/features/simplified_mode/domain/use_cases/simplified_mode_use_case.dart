import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

/// The simplified mode's reads and writes, composed from the medication,
/// measurement, appointment, circle and prayer-time features: it has no
/// endpoint of its own.
@lazySingleton
class SimplifiedModeUseCase {
  SimplifiedModeUseCase(
    this._home,
    this._medications,
    this._measurements,
    this._appointments,
    this._circles,
    this._prayers,
    this._reminders,
    this._calendar,
  );

  final HomeUseCase _home;
  final MedicationsUseCase _medications;
  final MeasurementRepository _measurements;
  final AppointmentRepository _appointments;
  final CirclesUseCase _circles;
  final PrayerTimesRepository _prayers;
  final DoseReminders _reminders;
  final CalendarSync _calendar;

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
    final CareCircleSummary? circle =
        account.circles.where((item) => item.isPatient).firstOrNull ??
        account.circles.firstOrNull;
    if (circle == null) return const Error(EmptyDataFailure());

    final DateTime today = circle.clock.today(now);
    final DateTime tomorrow = addDays(today, 1);
    final (doses, measurements, appointments) = await (
      _medications.getOccurrences(circle.id, today, tomorrow),
      _attempt(() => _measurements.occurrences(circle.id, today, today)),
      _attempt(() => _appointments.appointments(circle.id)),
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
        family: <CircleMember>[
          for (final CircleMember member
              in overview.tryGetSuccess()?.members ?? const <CircleMember>[])
            if (!member.isPatient &&
                !member.isYou &&
                member.phoneNumber != null)
              member,
        ],
        reasons: <String, String>{
          for (final MedicationPlan plan
              in plans.tryGetSuccess() ?? const <MedicationPlan>[])
            if (plan.version.reason case final String reason
                when reason.trim().isNotEmpty)
              plan.id: reason.trim(),
        },
        prayers: prayers.tryGetSuccess(),
      ),
    );
  }

  /// Keeps the phone's reminders, and the calendar copy the person chose,
  /// set for [day]'s circle, as the detailed home does for its circles.
  Future<void> keepReminding(SimplifiedDay day) {
    final List<ReminderCircle> circles = <ReminderCircle>[
      ReminderCircle(
        id: day.circleId,
        name: day.circleName,
        viewerId: day.accountId,
        viewerIsPatient: day.isPatient,
        timeZone: day.timeZone,
      ),
    ];
    return (_reminders.sync(circles), _calendar.sync(circles)).wait;
  }

  /// Reads the week of reminders again: the app came back to the front.
  Future<void> refreshReminders() =>
      (_reminders.refresh(), _calendar.refresh()).wait;

  /// Records [dose] as taken at [takenAt]. Its snooze goes with the
  /// reminders' next reading, which the record starts.
  Future<Result<DoseRecord, Failure>> takeDose(
    String circleId,
    DoseOccurrence dose,
    DateTime takenAt,
  ) => _medications.recordDose(
    circleId,
    dose,
    DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt),
  );

  /// «ذكّرني لاحقًا» on [task] of [circleId]: the same as the detailed
  /// mode's, so its reminder, its card and its calendar copy move to
  /// [after] from now.
  Future<void> snooze(String circleId, TodayTask task, Duration after) async {
    if (task.dose case final DoseOccurrence dose) {
      await _reminders.snoozeDose(circleId, dose, after);
    } else if (task.measurement case final MeasurementOccurrence measurement) {
      await _reminders.snoozeMeasurement(circleId, measurement, after);
    }
  }

  /// «ذكّرني لاحقًا» pressed in a notification: its task comes again, as
  /// in the detailed mode. False when [tap] is not that button.
  Future<bool> snoozeFromNotification(String tap) => _reminders.snoozeTap(tap);

  /// The tasks put off, by [TodayTask.snoozeKey], until each comes again.
  ValueListenable<Map<String, TaskSnooze>> get snoozes => _reminders.snoozes;

  /// The saved targets: the server refuses a free reading of a kind with
  /// none.
  Future<Result<List<MeasurementTarget>, Failure>> measurementTargets(
    String circleId,
  ) => _attempt(() => _measurements.targets(circleId));

  /// Saves a reading: against [occurrence] when the patient opened it from
  /// that task, else as a free reading under the saved target. A recorded
  /// task's snooze goes with the reminders' next reading.
  Future<Result<MeasurementReading, Failure>> recordMeasurement(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) => _attempt(
    () => _measurements.record(circleId, draft, occurrence: occurrence),
  );

  /// The measurement and appointment repositories throw; this turns their
  /// errors into the same failures the other features return.
  static Future<Result<T, Failure>> _attempt<T extends Object>(
    Future<T> Function() call,
  ) async {
    try {
      return Success(await call());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
