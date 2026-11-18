import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/features/home/presentation/widgets/weather_capsule.dart';
import 'package:app/features/home/presentation/widgets/weather_now.dart';
import 'package:flutter/material.dart';

/// The weather now in the patient's city, on the date line under the
/// greeting of «اليوم»: its icon, the degrees in bold and the condition in
/// words. A tap opens it large with Apple's Weather mark and its data
/// sources. Nothing shows without the city's place or an answer, so the
/// page never waits for it.
class TodayWeather extends StatelessWidget {
  const TodayWeather({
    super.key,
    required this.latitude,
    required this.longitude,
    this.source,
  });

  final double? latitude;
  final double? longitude;

  /// The app's [WeatherSource] when null.
  final WeatherSource? source;

  @override
  Widget build(BuildContext context) => WeatherNow(
    latitude: latitude,
    longitude: longitude,
    source: source,
    builder: (BuildContext context, PatientWeather? weather) => weather == null
        ? const SizedBox.shrink()
        : WeatherCapsule(weather: weather),
  );
}
