import 'package:app/core/utils/time_zones.dart';
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

  @override
  List<Object?> get props => [date, city, times, timeZone];
}
