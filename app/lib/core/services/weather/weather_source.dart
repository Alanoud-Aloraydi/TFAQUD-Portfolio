import 'package:app/core/services/weather/patient_weather.dart';

/// Reads [PatientWeather] for a place.
abstract interface class WeatherSource {
  /// The weather now at [latitude], [longitude]; null when there is none to
  /// show (not an iPhone, before iOS 16, no network).
  Future<PatientWeather?> now(double latitude, double longitude);
}
