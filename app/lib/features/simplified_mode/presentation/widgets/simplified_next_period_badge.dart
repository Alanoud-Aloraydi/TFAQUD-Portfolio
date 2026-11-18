import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// «بعد المغرب», the pill on the corner of the next card's picture.
class SimplifiedNextPeriodBadge extends StatelessWidget {
  const SimplifiedNextPeriodBadge({super.key, required this.period});

  final PrayerPeriod period;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 14,
      start: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: SimplifiedColors.surface,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          simplifiedPeriod(context, period),
          style: SimplifiedStyle.head(SimplifiedStyle.caption),
        ),
      ),
    );
  }
}
