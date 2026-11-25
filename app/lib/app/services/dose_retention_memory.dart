import 'package:shared_preferences/shared_preferences.dart';

/// The last day whose doses the person exported, or set the warning aside
/// for, on this phone, by circle: the warning before doses are deleted
/// says nothing more about those days.
class DoseRetentionMemory {
  const DoseRetentionMemory();

  static String _key(String circleId) => 'dose_retention_settled_$circleId';

  Future<DateTime?> settled(String circleId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? day = prefs.getString(_key(circleId));
    return day == null ? null : DateTime.tryParse(day);
  }

  Future<void> settle(String circleId, DateTime through) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime day = DateTime(through.year, through.month, through.day);
    await prefs.setString(_key(circleId), day.toIso8601String());
  }
}
