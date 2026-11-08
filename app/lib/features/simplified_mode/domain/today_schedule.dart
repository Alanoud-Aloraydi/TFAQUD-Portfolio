import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

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

/// Today's doses, measurements and appointments in time order, each with
/// its status at one moment. Statuses are worked out here from the times,
/// not taken from the server's reading, so the screen stays right as the
/// minutes pass without reading the server again.
class TodaySchedule {
  TodaySchedule._({
    required List<TodayTask> tasks,
    required this.firstDoseTomorrow,
    required this.upcomingAppointment,
    required this._wallNow,
  }) : tasks = List<TodayTask>.unmodifiable(tasks);

  /// [now] is an instant; [doses] may include tomorrow's (for
  /// [firstDoseTomorrow]); [appointments] may be of any day.
  factory TodaySchedule.build({
    required DateTime now,
    required List<DoseOccurrence> doses,
    required List<MeasurementOccurrence> measurements,
    required List<CareAppointment> appointments,
  }) {
    final DateTime wall = riyadhNow(now);
    final DateTime today = scheduleDay(wall);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final List<TodayTask> raw = <TodayTask>[
      for (final DoseOccurrence dose in doses)
        if (_sameDay(dose.scheduledOn, today))
          TodayTask.medication(dose, _doseStatus(dose, wall)),
      for (final MeasurementOccurrence item in measurements)
        if (_sameDay(item.scheduledOn, today))
          TodayTask.measurement(item, _measurementStatus(item, now)),
      for (final CareAppointment item in appointments)
        if (_sameDay(item.scheduledOn, today) &&
            item.status != AppointmentStatus.cancelled)
          TodayTask.appointment(item, _appointmentStatus(item, wall)),
    ]..sort(_byTime);

    // The first task still to come is «التالي»; the rest wait «لاحقًا».
    final List<TodayTask> tasks = List<TodayTask>.of(raw);
    final int next = tasks.indexWhere(
      (task) => task.status == TodayTaskStatus.later,
    );
    if (next != -1) tasks[next] = tasks[next].withStatus(TodayTaskStatus.next);

    final List<DoseOccurrence> tomorrowDoses = <DoseOccurrence>[
      for (final DoseOccurrence dose in doses)
        if (_sameDay(dose.scheduledOn, tomorrow) && dose.record == null) dose,
    ]..sort((a, b) => a.time.compareTo(b.time));

    final List<CareAppointment> coming = <CareAppointment>[
      for (final CareAppointment item in appointments)
        if (item.status == AppointmentStatus.scheduled &&
            item.scheduledAt.isAfter(wall))
          item,
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return TodaySchedule._(
      tasks: tasks,
      firstDoseTomorrow: tomorrowDoses.firstOrNull,
      upcomingAppointment: coming.firstOrNull,
      wallNow: wall,
    );
  }

  final List<TodayTask> tasks;

  /// Tomorrow's first dose, for «أول دواء غدًا ...»; null when none.
  final DoseOccurrence? firstDoseTomorrow;

  /// The nearest scheduled appointment still to come, on any day: what an
  /// appointment reminder is about.
  final CareAppointment? upcomingAppointment;
  final DateTime _wallNow;

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

  /// The dose or measurement ([kind]) a full-screen reminder asks about:
  /// the most recent one whose time came and is not recorded (the one the
  /// reminder fired for), else the next task when it is of [kind] and can
  /// already be recorded. Null when nothing of [kind] waits.
  TodayTask? taskToRecord(TodayTaskKind kind) {
    final TodayTask? due = tasks
        .where(
          (task) =>
              task.kind == kind &&
              task.status != TodayTaskStatus.done &&
              !task.scheduledAt.isAfter(_wallNow),
        )
        .lastOrNull;
    if (due != null) return due;
    final TodayTask? coming = next;
    if (coming != null && coming.kind == kind && canRecord(coming)) {
      return coming;
    }
    return null;
  }

  /// Whether [task] can be recorded now: not resolved, and not more than an
  /// hour before its time (the rule every «اليوم» row follows).
  bool canRecord(TodayTask task) => canRecordOccurrence(
    resolved: task.status == TodayTaskStatus.done,
    scheduledAt: task.scheduledAt,
    now: _wallNow,
  );

  static TodayTaskStatus _doseStatus(DoseOccurrence dose, DateTime wall) {
    if (dose.record != null) return TodayTaskStatus.done;
    return switch (medicationTimingState(dose, wall)) {
      DoseTimingState.late || DoseTimingState.missed => TodayTaskStatus.late,
      _ => TodayTaskStatus.later,
    };
  }

  /// The server's status is read once; the deadline it sends keeps the
  /// status right after that.
  static TodayTaskStatus _measurementStatus(
    MeasurementOccurrence item,
    DateTime now,
  ) {
    if (item.record != null) return TodayTaskStatus.done;
    if (now.isAfter(item.deadlineAt)) return TodayTaskStatus.late;
    return TodayTaskStatus.later;
  }

  /// An appointment needs no recording here: once its time comes it is
  /// behind the patient.
  static TodayTaskStatus _appointmentStatus(
    CareAppointment item,
    DateTime wall,
  ) {
    if (item.status == AppointmentStatus.completed ||
        !item.scheduledAt.isAfter(wall)) {
      return TodayTaskStatus.done;
    }
    return TodayTaskStatus.later;
  }

  static int _byTime(TodayTask a, TodayTask b) {
    final int byTime = a.scheduledAt.compareTo(b.scheduledAt);
    return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
