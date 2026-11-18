import 'package:equatable/equatable.dart';

/// What the server is told when a task is put off on this phone: the
/// body of `PUT /circles/{id}/task-snoozes`.
class SnoozeShare extends Equatable {
  const SnoozeShare({
    required this.circleId,
    required this.task,
    required this.taskId,
    required this.scheduledOn,
    required this.minutes,
    this.time,
  });

  final String circleId;

  /// «dose» or «measurement».
  final String task;

  /// The dose's schedule, or the reading's plan version.
  final String taskId;

  /// «2026-11-09».
  final String scheduledOn;

  /// A reading time's «08:00»; null for a dose (its schedule has it).
  final String? time;
  final int minutes;

  Map<String, Object> toJson() => <String, Object>{
    'task': task,
    'task_id': taskId,
    'scheduled_on': scheduledOn,
    'time_of_day': ?time,
    'minutes': minutes,
  };

  @override
  List<Object?> get props => [
    circleId,
    task,
    taskId,
    scheduledOn,
    time,
    minutes,
  ];
}
