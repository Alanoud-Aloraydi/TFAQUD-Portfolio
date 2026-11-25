import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/home/presentation/widgets/weather_icon.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

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

class SimplifiedMedicalFileRow extends StatelessWidget {
  const SimplifiedMedicalFileRow({
    super.key,
    required this.label,
    required this.value,
    required this.last,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: SimplifiedStyle.gap),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: SimplifiedColors.disabled),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                weight: AppTextTheme.medium,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: SimplifiedStyle.head(SimplifiedStyle.title)),
          ],
        ),
      ),
    );
  }
}
