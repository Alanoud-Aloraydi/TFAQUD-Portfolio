import 'dart:async';

import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/weather_icon.dart';
import 'package:app/features/home/presentation/widgets/weather_sheet.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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
