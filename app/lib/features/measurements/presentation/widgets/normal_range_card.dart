import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «المعدل الطبيعي»: the normal values of one range set large, which range
/// it is (meal state and the patient's condition) under them, and the four
/// levels as a scale, the one of [level] marked. The ranges are fixed; the
/// medical file chooses the condition, which [action] can lead to or
/// change.
class NormalRangeCard extends StatelessWidget {
  const NormalRangeCard({
    super.key,
    required this.range,
    this.level,
    this.footer,
    this.action,
  });

  final NormalRange range;

  /// The level of the value being typed or shown; null marks none.
  final MeasurementLevel? level;

  /// Under the card, such as where the condition comes from.
  final String? footer;

  /// A row under the scale, such as «تغيير الحالة في الملف الطبي».
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final MeasurementKind kind = range.kind;
    return InsetGroup(
      header: context.tr('measurements.normal_range'),
      footer: footer,
      children: [
        InsetBlock(
          semanticLabel: context.tr('measurements.normal_range'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      normalBandText(context, kind, range.normal),
                      style: text.headlineSmall?.copyWith(
                        fontWeight: AppTextTheme.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr(
                      kind == MeasurementKind.bp
                          ? 'measurements.bp_unit'
                          : 'measurements.glucose_unit',
                    ),
                    style: text.bodyMedium?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                normalRangeCaption(context, kind, range.profile, range.state),
                style: text.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Scale(range: range, level: level),
              if (level case final MeasurementLevel current) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      context.tr('measurements.your_reading'),
                      style: text.bodyMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MeasurementLevelBadge(level: current, kind: kind),
                  ],
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// The four levels side by side, lowest at the start, each with its name
/// and values; the one of [level] framed and bold.
class _Scale extends StatelessWidget {
  const _Scale({required this.range, this.level});

  final NormalRange range;
  final MeasurementLevel? level;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppTokens tokens = context.tokens;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final NormalBand band in range.bands) ...[
            if (band != range.bands.first) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                decoration: ShapeDecoration(
                  color: band.level.scaleFill,
                  shape: AppRadius.shape(
                    AppRadius.s,
                    side: band.level == level
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
                      band.level.label(context, range.kind),
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(
                        fontWeight: band.level == level
                            ? AppTextTheme.bold
                            : AppTextTheme.medium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      normalBandText(context, range.kind, band),
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
