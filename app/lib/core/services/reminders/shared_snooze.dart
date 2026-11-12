import 'package:equatable/equatable.dart';

/// A dose or reading time someone in the circle put off with «ذكّرني
/// لاحقًا», as the server keeps it for everyone: when it comes again
/// ([remindAt]), for how many [minutes], and who put it off. Every member's
/// card shows it; at [remindAt] the server reminds every member but the one
/// who put it off (their own phone does).
class SharedSnooze extends Equatable {
  const SharedSnooze({
    required this.remindAt,
    required this.minutes,
    this.byAccountId,
    this.byName,
  });

  /// In UTC.
  final DateTime remindAt;
  final int minutes;

  /// Who put it off; null once that account was deleted.
  final String? byAccountId;
  final String? byName;

  /// The `snooze` of an occurrence; null when the task is not put off.
  static SharedSnooze? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final Object? remindAt = json['remind_at'];
    final Object? minutes = json['minutes'];
    if (remindAt is! String || minutes is! int) return null;
    final DateTime? at = DateTime.tryParse(remindAt);
    if (at == null) return null;
    final Object? by = json['snoozed_by'];
    return SharedSnooze(
      remindAt: at.toUtc(),
      minutes: minutes,
      byAccountId: by is Map<String, dynamic>
          ? by['account_id'] as String?
          : null,
      byName: by is Map<String, dynamic> ? by['name'] as String? : null,
    );
  }

  /// Whether it still waits at [now].
  bool waitsAt(DateTime now) => remindAt.isAfter(now.toUtc());

  @override
  List<Object?> get props => [remindAt, minutes, byAccountId, byName];
}

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

/// The [SnoozeShare] of the task kept by [key] (a `doseSnoozeKey` or a
/// `measurementSnoozeKey`), put off [after] from now; null for a key of
/// another shape.
SnoozeShare? snoozeShareOf(String key, Duration after) {
  final List<String> parts = key.split('|');
  // The server takes 1 to 720 minutes (12 hours).
  final int minutes = after.inMinutes.clamp(1, 720);
  if (parts.length == 3) {
    final String? day = _isoDay(parts[2]);
    if (day == null) return null;
    return SnoozeShare(
      circleId: parts[0],
      task: 'dose',
      taskId: parts[1],
      scheduledOn: day,
      minutes: minutes,
    );
  }
  if (parts.length == 5 && parts[1] == 'measurement') {
    final String? day = _isoDay(parts[4]);
    if (day == null) return null;
    return SnoozeShare(
      circleId: parts[0],
      task: 'measurement',
      taskId: parts[2],
      scheduledOn: day,
      time: parts[3],
      minutes: minutes,
    );
  }
  return null;
}

/// «2026-11-09» for a key's «2026-11-9».
String? _isoDay(String value) {
  final List<String> parts = value.split('-');
  if (parts.length != 3) return null;
  final List<int?> numbers = parts.map(int.tryParse).toList();
  if (numbers.contains(null)) return null;
  return '${numbers[0]}-'
      '${numbers[1].toString().padLeft(2, '0')}-'
      '${numbers[2].toString().padLeft(2, '0')}';
}
