import 'dart:async';

import 'package:app/core/services/weather/patient_weather.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Reads the weather at [latitude], [longitude] and hands it to [builder];
/// [builder] gets null while there is no place, no source or no answer, so
/// a page never waits for the weather. Both modes read it through this one
/// widget, so the asking happens in one place.
class WeatherNow extends StatefulWidget {
  const WeatherNow({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.builder,
    this.source,
  });

  final double? latitude;
  final double? longitude;
  final Widget Function(BuildContext context, PatientWeather? weather) builder;

  /// The app's [WeatherSource] when null.
  final WeatherSource? source;

  @override
  State<WeatherNow> createState() => _WeatherNowState();
}

class _WeatherNowState extends State<WeatherNow> {
  PatientWeather? _shown;
  int _asked = 0;

  WeatherSource? get _source =>
      widget.source ??
      (GetIt.I.isRegistered<WeatherSource>() ? GetIt.I<WeatherSource>() : null);

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  /// The page rebuilds each minute: the source answers from its last
  /// reading until that is old, so this asks Apple twice an hour at most.
  @override
  void didUpdateWidget(WeatherNow oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_read());
  }

  Future<void> _read() async {
    final int ask = ++_asked;
    final double? latitude = widget.latitude;
    final double? longitude = widget.longitude;
    final WeatherSource? source = _source;
    final PatientWeather? weather =
        latitude == null || longitude == null || source == null
        ? null
        : await source.now(latitude, longitude);
    if (!mounted || ask != _asked || weather == _shown) return;
    setState(() => _shown = weather);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shown);
}
