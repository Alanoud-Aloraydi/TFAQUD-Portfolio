import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/normal_band_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The normal values of [range] set large, with their unit beside them.
class NormalRangeValue extends StatelessWidget {
  const NormalRangeValue({super.key, required this.range});

  final NormalRange range;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final MeasurementKind kind = range.kind;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            normalBandText(context, kind, range.normal),
            style: text.headlineSmall?.copyWith(fontWeight: AppTextTheme.bold),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.tr(
            kind == MeasurementKind.bp
                ? 'measurements.bp_unit'
                : 'measurements.glucose_unit',
          ),
          style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
