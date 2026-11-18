import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/features/home/presentation/widgets/weather_icon.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// What the weather looks like in this mode: the icon and the degrees
/// large on one line, the condition in words under them.
class SimplifiedWeatherTile extends StatelessWidget {
  const SimplifiedWeatherTile({
    super.key,
    required this.weather,
    required this.condition,
  });

  final PatientWeather weather;
  final String condition;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SimplifiedStyle.touch),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(weatherIcon(weather), size: 26),
              const SizedBox(width: 8),
              Text(
                context.tr(
                  'weather.degrees',
                  args: <String>['${weather.degrees}'],
                ),
                style: SimplifiedStyle.head(SimplifiedStyle.headline),
              ),
            ],
          ),
          Text(
            condition,
            style: SimplifiedStyle.text(
              SimplifiedStyle.caption,
              color: SimplifiedColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
