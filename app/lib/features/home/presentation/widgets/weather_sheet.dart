import 'dart:async';

import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/home/presentation/widgets/weather_icon.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The weather's sheet: the weather large, then Apple's Weather mark and
/// its data sources, which Apple asks to show with its weather. Both modes
/// open this one sheet, so the mark is shown wherever the weather is.
Future<void> showWeatherSheet(
  BuildContext context,
  PatientWeather weather,
  String condition,
) => showGlassSheet<void>(
  context,
  title: context.tr('weather.title'),
  message: context.tr('weather.note'),
  builder: (BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(weatherIcon(weather), size: AppSizes.avatar),
            const SizedBox(width: AppSpacing.md),
            Text(
              context.tr(
                'weather.degrees',
                args: <String>['${weather.degrees}'],
              ),
              style: text.displaySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(condition, textAlign: TextAlign.center, style: text.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        // Apple's Weather mark, and its data sources.
        Center(
          child: Image.network(
            dark ? weather.markDark : weather.markLight,
            height: 16,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => unawaited(
              launchUrl(
                Uri.parse(weather.legalPage),
                mode: LaunchMode.externalApplication,
              ),
            ),
            child: Text(context.tr('weather.sources')),
          ),
        ),
      ],
    );
  },
);
