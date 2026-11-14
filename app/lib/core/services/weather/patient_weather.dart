import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The weather now in the patient's city, from Apple Weather (WeatherKit)
/// on the phone, with what Apple asks to show beside it: its mark and a
/// link to its legal page.
class PatientWeather extends Equatable {
  const PatientWeather({
    required this.temperature,
    required this.condition,
    required this.isDaylight,
    required this.markLight,
    required this.markDark,
    required this.legalPage,
  });

  /// In °C.
  final double temperature;

  /// WeatherKit's condition: `clear`, `mostlyCloudy`, `rain`…
  final String condition;
  final bool isDaylight;

  /// The Apple Weather mark for a light and a dark background.
  final String markLight;
  final String markDark;

  /// Apple's page of the data sources, which the mark links to.
  final String legalPage;

  /// «24°».
  int get degrees => temperature.round();

  /// What the iOS channel answers; null for an answer it cannot read.
  static PatientWeather? fromMap(Map<String, dynamic>? value) {
    if (value == null) return null;
    final Object? temperature = value['temperature'];
    final Object? condition = value['condition'];
    final Object? light = value['mark_light'];
    final Object? dark = value['mark_dark'];
    final Object? legal = value['legal_page'];
    if (temperature is! num ||
        condition is! String ||
        light is! String ||
        dark is! String ||
        legal is! String) {
      return null;
    }
    return PatientWeather(
      temperature: temperature.toDouble(),
      condition: condition,
      isDaylight: value['is_daylight'] != false,
      markLight: light,
      markDark: dark,
      legalPage: legal,
    );
  }

  @override
  List<Object?> get props => [
    temperature,
    condition,
    isDaylight,
    markLight,
    markDark,
    legalPage,
  ];
}

/// Reads [PatientWeather] for a place.
abstract interface class WeatherSource {
  /// The weather now at [latitude], [longitude]; null when there is none to
  /// show (not an iPhone, before iOS 16, no network).
  Future<PatientWeather?> now(double latitude, double longitude);
}

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
