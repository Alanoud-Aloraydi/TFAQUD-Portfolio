import 'dart:async';

import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/weather_icon.dart';
import 'package:app/features/home/presentation/widgets/weather_now.dart';
import 'package:app/features/home/presentation/widgets/weather_sheet.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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

/// The weather as a tappable capsule: icon, degrees in bold and the
/// condition in words. A tap opens it large.
class WeatherCapsule extends StatelessWidget {
  const WeatherCapsule({super.key, required this.weather});

  final PatientWeather weather;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
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
        borderRadius: BorderRadius.circular(AppRadius.capsule),
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(weatherIcon(weather), size: AppSizes.iconSmall),
              const SizedBox(width: AppSpacing.tight),
              Text(
                context.tr(
                  'weather.degrees',
                  args: <String>['${weather.degrees}'],
                ),
                style: text.bodySmall?.copyWith(
                  fontWeight: AppTextTheme.bold,
                  color: AppSemanticColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Flexible(child: Text(condition, style: text.bodySmall)),
            ],
          ),
        ),
      ),
    );
  }
}
