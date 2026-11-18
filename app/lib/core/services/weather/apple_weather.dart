import 'package:app/core/services/weather/patient_weather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Apple Weather through the iOS app (`AppDelegate.swift`): no key, and the
/// phone's own location is never asked for. One reading of a place serves
/// [maxAge], so the tab's minute clock costs no calls (the membership
/// includes 500,000 a month).
class AppleWeather implements WeatherSource {
  AppleWeather({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const MethodChannel channel = MethodChannel('tafaqod/weather');

  /// How long one reading stands.
  static const Duration maxAge = Duration(minutes: 30);

  final DateTime Function() _clock;
  final Map<String, (DateTime, PatientWeather?)> _read =
      <String, (DateTime, PatientWeather?)>{};

  @override
  Future<PatientWeather?> now(double latitude, double longitude) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    // About a kilometre: the same city is one place.
    final String place =
        '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
    final DateTime now = _clock();
    if (_read[place] case (final DateTime at, final PatientWeather? cached)
        when now.difference(at) < maxAge) {
      return cached;
    }
    PatientWeather? weather;
    try {
      weather = PatientWeather.fromMap(
        await channel.invokeMapMethod<String, dynamic>('current', {
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
    } on PlatformException catch (error) {
      debugPrint('AppleWeather.now failed: $error');
    } on MissingPluginException catch (error) {
      debugPrint('AppleWeather.now failed: $error');
    }
    _read[place] = (now, weather);
    return weather;
  }
}
