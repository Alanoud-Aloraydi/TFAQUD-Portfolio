import 'dart:async';

import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/home/presentation/widgets/weather_now.dart';
import 'package:app/features/home/presentation/widgets/weather_sheet.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The weather in the account's own city, beside the greeting. A tap opens
/// the same sheet the detailed mode opens, which carries Apple's Weather
/// mark and its sources. Nothing shows without a place or an answer, so
/// the home never waits for it.
class SimplifiedWeather extends StatelessWidget {
  const SimplifiedWeather({
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
    builder: (BuildContext context, PatientWeather? weather) =>
        weather == null ? const SizedBox.shrink() : _tap(context, weather),
  );

  Widget _tap(BuildContext context, PatientWeather weather) {
    final String condition = context.tr(
      'weather.condition.${weather.condition}',
    );
    void open() => unawaited(showWeatherSheet(context, weather, condition));
    return Semantics(
      button: true,
      label: spoken(
        context.tr(
          'weather.spoken',
          args: <String>['${weather.degrees}', condition],
        ),
      ),
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
        onTap: open,
        child: SimplifiedWeatherTile(weather: weather, condition: condition),
      ),
    );
  }
}

/// A white rounded card with a light edge.
class SimplifiedCard extends StatelessWidget {
  const SimplifiedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SimplifiedStyle.pad),
    this.color = SimplifiedColors.surface,
    this.side = const BorderSide(color: SimplifiedColors.line),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final BorderSide side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
      side: side,
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
