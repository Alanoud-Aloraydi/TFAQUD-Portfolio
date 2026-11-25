import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:flutter/material.dart';

/// A red-worded capsule for leaving or deleting the account.
class SimplifiedOutlinedDanger extends StatelessWidget {
  const SimplifiedOutlinedDanger({
    super.key,
    required this.label,
    required this.busy,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool busy;

  /// White behind it with a light edge; else only a red edge.
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: const StadiumBorder(),
        backgroundColor: filled
            ? SimplifiedColors.surface
            : SimplifiedColors.clear,
        side: BorderSide(
          color: filled ? SimplifiedColors.line : SimplifiedColors.danger,
          width: filled ? 1 : 1.5,
        ),
        foregroundColor: SimplifiedColors.danger,
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(
              label,
              style: SimplifiedStyle.head(
                SimplifiedStyle.body,
                color: SimplifiedColors.danger,
              ),
            ),
    );
  }
}

/// The greeting and the date of «اليوم», with the weather beside them.
class SimplifiedHomeHeading extends StatelessWidget {
  const SimplifiedHomeHeading({
    super.key,
    required this.day,
    required this.now,
  });

  final SimplifiedDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 12,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              simplifiedGreeting(context, day.displayName, now, day.prayers),
              style: SimplifiedStyle.head(SimplifiedStyle.display),
            ),
            const SizedBox(height: 6),
            Text(
              simplifiedToday(context, now),
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                weight: AppTextTheme.medium,
              ),
            ),
          ],
        ),
        // The weather where the patient lives, beside the greeting as
        // it is beside the date in «اليوم». It wraps under the
        // greeting when the text is large.
        SimplifiedWeather(latitude: day.latitude, longitude: day.longitude),
      ],
    );
  }
}
