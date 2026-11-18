import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:flutter/material.dart';

/// One level of the scale: its icon, name and values; framed and bold when
/// it is the level of the value shown ([marked]).
class NormalRangeBandCell extends StatelessWidget {
  const NormalRangeBandCell({
    super.key,
    required this.band,
    required this.kind,
    required this.marked,
  });

  final NormalBand band;
  final MeasurementKind kind;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: ShapeDecoration(
        color: band.level.scaleFill,
        shape: AppRadius.shape(
          AppRadius.s,
          side: marked
              ? BorderSide(color: tokens.focus, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(band.level.icon, size: 14),
          const SizedBox(height: 2),
          Text(
            band.level.label(context, kind),
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(
              fontWeight: marked ? AppTextTheme.bold : AppTextTheme.medium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            normalBandText(context, kind, band),
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
