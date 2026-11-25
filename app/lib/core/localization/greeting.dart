import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Whether [now] (the patient's wall time) is morning: from Fajr until
/// Dhuhr. [fajr] and [dhuhr] are today's times («HH:mm»); before they are
/// loaded, [_fallbackFajr] and [_fallbackDhuhr], a rough middle of the year
/// at mid latitudes.
bool isMorning(DateTime now, {String? fajr, String? dhuhr}) {
  final int minute = now.hour * 60 + now.minute;
  final int morning = _minuteOf(fajr) ?? _minuteOf(_fallbackFajr)!;
  final int evening = _minuteOf(dhuhr) ?? _minuteOf(_fallbackDhuhr)!;
  return minute >= morning && minute < evening;
}

/// Where morning and evening start while today's prayer times load.
const String _fallbackFajr = '04:30';
const String _fallbackDhuhr = '12:00';

/// «HH:mm» in minutes from midnight, or null.
int? _minuteOf(String? time) {
  final List<String>? parts = time?.split(':');
  if (parts == null || parts.length < 2) return null;
  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);
  return hour == null || minute == null ? null : hour * 60 + minute;
}

/// «صباح الخير، ياسر» from Fajr until Dhuhr where the patient lives ([now]
/// is the patient's wall time), «مساء الخير، ياسر» from Dhuhr until the
/// next Fajr ([isMorning]); without a name, the greeting alone.
String greeting(
  BuildContext context,
  DateTime now,
  String? name, {
  String? fajr,
  String? dhuhr,
}) {
  final String key = isMorning(now, fajr: fajr, dhuhr: dhuhr)
      ? 'today_dashboard.good_morning'
      : 'today_dashboard.good_evening';
  final String? shown = name?.trim();
  return shown == null || shown.isEmpty
      ? context.tr(key)
      : context.tr('${key}_name', args: <String>[shown]);
}
