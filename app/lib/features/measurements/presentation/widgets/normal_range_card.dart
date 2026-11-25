import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_scale.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_value.dart';
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
    return InsetGroup(
      header: context.tr('measurements.normal_range'),
      footer: footer,
      children: [
        InsetBlock(
          semanticLabel: context.tr('measurements.normal_range'),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NormalRangeValue(range: range),
                const SizedBox(height: AppSpacing.xs),
                NormalRangeCaptionLine(range: range),
                const SizedBox(height: AppSpacing.md),
                NormalRangeScale(range: range, level: level),
                if (level case final MeasurementLevel current) ...[
                  const SizedBox(height: AppSpacing.md),
                  NormalRangeYourReading(level: current, kind: range.kind),
                ],
              ],
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Which range [range] is (meal state and the patient's condition), under
/// its values.
class NormalRangeCaptionLine extends StatelessWidget {
  const NormalRangeCaptionLine({super.key, required this.range});

  final NormalRange range;

  @override
  Widget build(BuildContext context) => Text(
    normalRangeCaption(context, range.kind, range.profile, range.state),
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.tokens.textSecondary),
  );
}
