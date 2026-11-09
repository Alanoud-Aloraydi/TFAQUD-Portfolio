import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:equatable/equatable.dart';

/// A task put off with «ذكّرني لاحقًا»: which one ([kind], its [day] and
/// [time]) and the instant [until] it is reminded of again. Kept on the
/// phone, so the screens say «سأذكّرك 2:09 مساءً» on it until then.
class SimplifiedSnooze extends Equatable {
  const SimplifiedSnooze({
    required this.kind,
    required this.day,
    required this.time,
    required this.until,
  });

  /// The snooze of [task], [after] from [now].
  SimplifiedSnooze.of(TodayTask task, DateTime now, Duration after)
    : this(
        kind: task.kind,
        day: task.day,
        time: task.time,
        until: now.toUtc().add(after),
      );

  final TodayTaskKind kind;

  /// The task's day (date only) and its «HH:mm» Riyadh time.
  final DateTime day;
  final String time;

  /// When the reminder comes again, in UTC.
  final DateTime until;

  /// Whether this puts off [task]; a recorded task is no longer put off.
  bool covers(TodayTask task) =>
      task.status != TodayTaskStatus.done &&
      task.kind == kind &&
      task.time == time &&
      task.day.year == day.year &&
      task.day.month == day.month &&
      task.day.day == day.day;

  /// Whether the reminder has come at [now], so the snooze is over.
  bool isOver(DateTime now) => !until.isAfter(now.toUtc());

  /// The same task, reminded of again [after] from [now].
  SimplifiedSnooze again(DateTime now, Duration after) => SimplifiedSnooze(
    kind: kind,
    day: day,
    time: time,
    until: now.toUtc().add(after),
  );

  Map<String, Object> toJson() => <String, Object>{
    'kind': kind.name,
    'day':
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}',
    'time': time,
    'until': until.toUtc().toIso8601String(),
  };

  /// Null for anything that is not a saved snooze.
  static SimplifiedSnooze? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? kind = json['kind'];
    final DateTime? day = DateTime.tryParse('${json['day']}');
    final Object? time = json['time'];
    final DateTime? until = DateTime.tryParse('${json['until']}');
    final TodayTaskKind? taskKind = TodayTaskKind.values
        .where((TodayTaskKind value) => value.name == kind)
        .firstOrNull;
    if (taskKind == null || day == null || time is! String || until == null) {
      return null;
    }
    return SimplifiedSnooze(
      kind: taskKind,
      day: DateTime(day.year, day.month, day.day),
      time: time,
      until: until.toUtc(),
    );
  }

  @override
  List<Object?> get props => [kind, day, time, until];
}
