import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';

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
