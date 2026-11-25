import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The calendars the app writes its dates in.
enum DateCalendar { hijri, gregorian }

/// Which calendar this phone shows the dates in: هجري until the person
/// picks in «حسابي» (either mode). The whole app is built again when it
/// changes (main.dart), so every date follows at once. The days the app
/// keeps and sends stay Gregorian: only how they are written changes.
abstract final class AppCalendar {
  static const String _key = 'date_calendar';

  static final ValueNotifier<DateCalendar> choice = ValueNotifier<DateCalendar>(
    DateCalendar.hijri,
  );

  /// The choice saved on this phone, read once before the app shows.
  static Future<void> restore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_key);
    choice.value = DateCalendar.values.firstWhere(
      (DateCalendar value) => value.name == saved,
      orElse: () => DateCalendar.hijri,
    );
  }

  static Future<void> choose(DateCalendar value) async {
    choice.value = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}
