import 'package:equatable/equatable.dart';

enum Prayer { fajr, dhuhr, asr, maghrib, isha }

class PrayerDay extends Equatable {
  PrayerDay({
    required this.date,
    required this.city,
    required Map<Prayer, String> times,
  }) : times = Map.unmodifiable(times);

  final DateTime date;
  final String city;
  final Map<Prayer, String> times;

  Prayer? nextPrayer(DateTime now) {
    final saudiNow = now.toUtc().add(const Duration(hours: 3));
    if (saudiNow.year != date.year ||
        saudiNow.month != date.month ||
        saudiNow.day != date.day) {
      return null;
    }
    final currentMinute = saudiNow.hour * 60 + saudiNow.minute;
    for (final prayer in Prayer.values) {
      final parts = times[prayer]!.split(':');
      final prayerMinute = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (prayerMinute > currentMinute) return prayer;
    }
    return null;
  }

  @override
  List<Object?> get props => [date, city, times];
}
