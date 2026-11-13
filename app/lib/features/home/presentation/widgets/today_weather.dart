import 'dart:async';

import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

/// The weather now in the patient's city, above the greeting of «اليوم»:
/// its icon, the degrees in bold and the condition in words, then Apple's
/// Weather mark and its data sources, which Apple asks to show beside its
/// weather. Nothing shows without the city's place or an answer, so the
/// page never waits for it.
class TodayWeather extends StatefulWidget {
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
  State<TodayWeather> createState() => _TodayWeatherState();
}

class _TodayWeatherState extends State<TodayWeather> {
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
  void didUpdateWidget(TodayWeather oldWidget) {
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
  Widget build(BuildContext context) {
    final PatientWeather? weather = _shown;
    if (weather == null) return const SizedBox.shrink();
    final TextTheme text = Theme.of(context).textTheme;
    final String condition = context.tr(
      'weather.condition.${weather.condition}',
    );
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              label: context.tr(
                'weather.spoken',
                args: <String>['${weather.degrees}', condition],
              ),
              excludeSemantics: true,
              child: Row(
                children: <Widget>[
                  Icon(weatherIcon(weather), size: AppSizes.icon),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr(
                      'weather.degrees',
                      args: <String>['${weather.degrees}'],
                    ),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      condition,
                      style: text.bodyMedium?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Apple's Weather mark, and its data sources.
          Semantics(
            link: true,
            label: context.tr('weather.sources'),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => unawaited(
                launchUrl(
                  Uri.parse(weather.legalPage),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.touch),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.network(
                      dark ? weather.markDark : weather.markLight,
                      height: 12,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      context.tr('weather.sources'),
                      style: text.labelSmall?.copyWith(
                        color: context.tokens.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The icon of WeatherKit's condition, by day or night.
IconData weatherIcon(PatientWeather weather) {
  final bool day = weather.isDaylight;
  return switch (weather.condition) {
    'clear' ||
    'hot' => day ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_stars_fill,
    'mostlyClear' || 'partlyCloudy' =>
      day ? CupertinoIcons.cloud_sun_fill : CupertinoIcons.cloud_moon_fill,
    'cloudy' || 'mostlyCloudy' => CupertinoIcons.cloud_fill,
    'drizzle' ||
    'rain' ||
    'heavyRain' ||
    'sunShowers' ||
    'freezingDrizzle' ||
    'freezingRain' => CupertinoIcons.cloud_rain_fill,
    'thunderstorms' ||
    'isolatedThunderstorms' ||
    'scatteredThunderstorms' ||
    'strongStorms' ||
    'tropicalStorm' ||
    'hurricane' => CupertinoIcons.cloud_bolt_rain_fill,
    'snow' ||
    'heavySnow' ||
    'flurries' ||
    'sunFlurries' ||
    'blizzard' ||
    'blowingSnow' ||
    'sleet' ||
    'wintryMix' ||
    'hail' ||
    'frigid' => CupertinoIcons.snow,
    'foggy' || 'haze' || 'smoky' => CupertinoIcons.cloud_fog_fill,
    'windy' || 'breezy' || 'blowingDust' => CupertinoIcons.wind,
    _ => CupertinoIcons.thermometer,
  };
}
