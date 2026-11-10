import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';

/// Maps prayer day data between the API and app.
class PrayerDayModel {
  const PrayerDayModel(this.day);

  final PrayerDay day;

  factory PrayerDayModel.fromJson(Map<String, dynamic> json) {
    final values = json['timings'] as Map<String, dynamic>;
    final times = <Prayer, String>{
      Prayer.fajr: values['Fajr'] as String,
      Prayer.dhuhr: values['Dhuhr'] as String,
      Prayer.asr: values['Asr'] as String,
      Prayer.maghrib: values['Maghrib'] as String,
      Prayer.isha: values['Isha'] as String,
    };
    if (times.values.any(
      (value) => !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value),
    )) {
      throw const FormatException('Invalid prayer time');
    }
    return PrayerDayModel(
      PrayerDay(
        date: DateTime.parse(json['date'] as String),
        city: json['city'] as String,
        times: times,
        timeZone: json['timezone'] as String? ?? defaultPatientZone,
      ),
    );
  }
}
