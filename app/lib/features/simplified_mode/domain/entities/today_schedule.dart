import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// Today's doses, measurements and appointments in time order, each with
/// its status at one moment. Statuses are worked out here from the times,
/// not taken from the server's reading, so the screen stays right as the
/// minutes pass without reading the server again.
class TodaySchedule {
  TodaySchedule._({
    required List<TodayTask> tasks,
    required this.firstDoseTomorrow,
    required this.upcomingAppointment,
    required this.wallNow,
  }) : tasks = List<TodayTask>.unmodifiable(tasks);

  /// [now] is an instant, read on the patient's [clock]; [doses] may
  /// include tomorrow's (for [firstDoseTomorrow]); [appointments] may be of
  /// any day.
  factory TodaySchedule.build({
    required PatientClock clock,
    required DateTime now,
    required List<DoseOccurrence> doses,
    required List<MeasurementOccurrence> measurements,
    required List<CareAppointment> appointments,
  }) {
    final DateTime wall = clock.wallTime(now);
    final DateTime today = scheduleDay(wall);
    final List<TodayTask> raw = <TodayTask>[
      for (final DoseOccurrence dose in doses)
        if (isSameDate(dose.scheduledOn, today))
          TodayTask.medication(dose, todayDoseStatus(dose, wall)),
      // A measurement nobody recorded leaves once the next one of its kind
      // is due: a reading now would be the same value, for that one.
      for (final MeasurementOccurrence item in measurements)
        if (isSameDate(item.scheduledOn, today) &&
            (item.record != null || !item.supersededAt(wall)))
          TodayTask.measurement(item, todayMeasurementStatus(item, now)),
      for (final CareAppointment item in appointments)
        if (isSameDate(item.scheduledOn, today) &&
            item.status != AppointmentStatus.cancelled)
          TodayTask.appointment(item, todayAppointmentStatus(item, wall)),
    ]..sort(todayTaskOrder);

    // The first task still to come is «التالي»; the rest wait «لاحقًا».
    final List<TodayTask> tasks = List<TodayTask>.of(raw);
    final int next = tasks.indexWhere(
      (task) => task.status == TodayTaskStatus.later,
    );
    if (next != -1) tasks[next] = tasks[next].withStatus(TodayTaskStatus.next);

    return TodaySchedule._(
      tasks: tasks,
      firstDoseTomorrow: firstDoseOn(doses, addDays(today, 1)),
      upcomingAppointment: nextAppointment(appointments, wall),
      wallNow: wall,
    );
  }

  final List<TodayTask> tasks;

  /// Tomorrow's first dose, for «أول دواء غدًا ...»; null when none.
  final DoseOccurrence? firstDoseTomorrow;

  /// The nearest scheduled appointment still to come, on any day: what an
  /// appointment reminder is about.
  final CareAppointment? upcomingAppointment;

  /// The patient's wall time the statuses were worked out at.
  final DateTime wallNow;
}

/// What the simplified home's one card shows.
enum HomeFocus {
  /// A dose whose time passed unrecorded: «هل أخذت هذا الدواء؟».
  lateDose,

  /// The next task still to come, or a measurement whose time passed.
  task,

  /// Every task of today is resolved: «أحسنت! أنجزت كل شيء».
  allDone,

  /// Nothing is scheduled today.
  empty,
}

/// Which task can be recorded now, and which one a reminder is about.
extension TodayScheduleRecording on TodaySchedule {
  /// The dose or measurement ([kind]) waiting now, for a reminder that
  /// names no task ([reminderTask]): the most recent one whose time came
  /// and is not recorded, else the next task when it is of [kind] and can
  /// already be recorded. Null when nothing of [kind] waits.
  TodayTask? taskToRecord(TodayTaskKind kind) {
    final TodayTask? due = tasks
        .where(
          (task) =>
              task.kind == kind &&
              task.status != TodayTaskStatus.done &&
              !task.scheduledAt.isAfter(wallNow),
        )
        .lastOrNull;
    if (due != null) return due;
    final TodayTask? coming = next;
    if (coming != null && coming.kind == kind && canRecord(coming)) {
      return coming;
    }
    return null;
  }

  /// The dose or measurement a reminder for [request] in [circleId] asks
  /// about, while it is still not recorded: that exact task by its key, or,
  /// without a key, the one of its kind waiting now ([taskToRecord]). Null
  /// when it was recorded (someone in the family may have), when it is of
  /// another circle or day, and for a visit (reminder_appointment.dart).
  TodayTask? reminderTask(ReminderRequest request, String circleId) {
    if (request.kind == TodayTaskKind.appointment) return null;
    final String? key = request.taskKey;
    if (key == null) return taskToRecord(request.kind);
    return tasks
        .where(
          (task) =>
              task.status != TodayTaskStatus.done &&
              task.snoozeKey(circleId) == key,
        )
        .firstOrNull;
  }

  /// Whether [task] can be recorded now: not resolved, and not more than an
  /// hour before its time (the rule every «اليوم» row follows).
  bool canRecord(TodayTask task) => canRecordOccurrence(
    resolved: task.status == TodayTaskStatus.done,
    scheduledAt: task.scheduledAt,
    now: wallNow,
  );
}

/// How the day stands as a whole, and the one task the home card shows.
extension TodayScheduleFocus on TodaySchedule {
  int get total => tasks.length;

  int get doneCount =>
      tasks.where((task) => task.status == TodayTaskStatus.done).length;

  TodayTask? get next =>
      tasks.where((task) => task.status == TodayTaskStatus.next).firstOrNull;

  /// The most recent dose whose time passed unrecorded.
  TodayTask? get lateDose => tasks
      .where(
        (task) =>
            task.kind == TodayTaskKind.medication &&
            task.status == TodayTaskStatus.late,
      )
      .lastOrNull;

  HomeFocus get focus {
    if (lateDose != null) return HomeFocus.lateDose;
    if (focusTask != null) return HomeFocus.task;
    if (tasks.isEmpty) return HomeFocus.empty;
    return HomeFocus.allDone;
  }

  /// The task the home card shows: the late dose, else the next task, else
  /// the most recent other task whose time passed unrecorded.
  TodayTask? get focusTask =>
      lateDose ??
      next ??
      tasks.where((task) => task.status == TodayTaskStatus.late).lastOrNull;
}
