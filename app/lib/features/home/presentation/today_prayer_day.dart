import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter/material.dart';

/// Today's prayer times, or null while they load (or are yesterday's).
PrayerDay? todayPrayerDay(PrayerTimesState prayers, DateTime now) =>
    prayers.day != null && DateUtils.isSameDay(prayers.day!.date, now)
    ? prayers.day
    : null;
