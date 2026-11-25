import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
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

/// «قراءتك» with the badge of the [level] the value typed or shown is in.
class NormalRangeYourReading extends StatelessWidget {
  const NormalRangeYourReading({
    super.key,
    required this.level,
    required this.kind,
  });

  final MeasurementLevel level;
  final MeasurementKind kind;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        context.tr('measurements.your_reading'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(width: AppSpacing.sm),
      MeasurementLevelBadge(level: level, kind: kind),
    ],
  );
}

/// Which range it is, in words: «صائم أو قبل الوجبة، مصاب بالسكري».
String normalRangeCaption(
  BuildContext context,
  MeasurementKind kind,
  String profile,
  String? state,
) {
  final String who = context.tr(
    'measurements.range_profile.${profile == 'general' ? '${kind.name}_general' : profile}',
  );
  if (kind == MeasurementKind.bp) return who;
  return '${context.tr('measurements.range_state.$state')}، $who';
}

/// «المعدل الطبيعي: 70–100 ملغ/دل، صائم أو قبل الوجبة، غير مصاب بالسكري»:
/// the range [reading] was judged by, in one line.
String readingRangeText(BuildContext context, MeasurementReading reading) {
  final ReadingRange range = reading.range!;
  final String unit = context.tr(
    reading.kind == MeasurementKind.bp
        ? 'measurements.bp_unit'
        : 'measurements.glucose_unit',
  );
  return '${context.tr('measurements.normal_range')}: '
      '${normalBandText(context, reading.kind, range.normal)} $unit، '
      '${normalRangeCaption(context, reading.kind, range.profile, range.state)}';
}
