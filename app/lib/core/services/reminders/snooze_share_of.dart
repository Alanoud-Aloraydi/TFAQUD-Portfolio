import 'package:app/core/services/reminders/snooze_share.dart';

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
