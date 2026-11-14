import 'package:app/core/utils/patient_clock.dart';
import 'package:equatable/equatable.dart';

enum Prayer { fajr, dhuhr, asr, maghrib, isha }

/// Holds prayer times for one calendar day of the patient's city.
class PrayerDay extends Equatable {
  PrayerDay({
    required this.date,
    required this.city,
    required Map<Prayer, String> times,
    this.timeZone = defaultPatientZone,
  }) : times = Map.unmodifiable(times);

  /// The patient's day these times are for.
  final DateTime date;
  final String city;

  /// «HH:mm» wall clock in [timeZone].
  final Map<Prayer, String> times;

  /// The IANA zone the times are in: the patient's ([defaultPatientZone]
  /// when an older server does not say).
  final String timeZone;

  /// The next prayer after the instant [now] on [date], read on the
  /// patient's clock; null once Isha passed or on another day.
  Prayer? nextPrayer(DateTime now) {
    final DateTime wall = PatientClock(timeZone).wallTime(now);
    if (wall.year != date.year ||
        wall.month != date.month ||
        wall.day != date.day) {
      return null;
    }
    final currentMinute = wall.hour * 60 + wall.minute;
    for (final prayer in Prayer.values) {
      final parts = times[prayer]!.split(':');
      final prayerMinute = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (prayerMinute > currentMinute) return prayer;
    }
    return null;
  }

  @override
  List<Object?> get props => [date, city, times, timeZone];
}
