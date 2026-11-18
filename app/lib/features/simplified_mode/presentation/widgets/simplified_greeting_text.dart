import 'package:app/core/l10n/greeting.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:flutter/widgets.dart';

/// The app's one greeting, the detailed mode's too: آ«طµط¨ط§ط­ ط§ظ„ط®ظٹط±طŒ ظ…ط±ظٹظ…آ»
/// from Fajr until Dhuhr, آ«ظ…ط³ط§ط، ط§ظ„ط®ظٹط±طŒ ظ…ط±ظٹظ…آ» after ([prayers] is today's;
/// without it, the fallback times of [isMorning]).
String simplifiedGreeting(
  BuildContext context,
  String? name,
  DateTime now,
  PrayerDay? prayers,
) => greeting(
  context,
  PatientClockScope.of(context).wallTime(now),
  name,
  fajr: prayers?.times[Prayer.fajr],
  dhuhr: prayers?.times[Prayer.dhuhr],
);
