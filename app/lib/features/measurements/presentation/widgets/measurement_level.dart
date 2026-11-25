import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How each level reads, looks and sounds, so a level is the same on every
/// page: words and an icon, never colour alone.
extension MeasurementLevelLook on MeasurementLevel {
  /// «منخفض», «طبيعي», «أعلى من الطبيعي» (glucose) or «طبيعي مرتفع» (blood
  /// pressure), «مرتفع».
  String label(BuildContext context, MeasurementKind kind) =>
      context.tr(switch (this) {
        MeasurementLevel.low => 'measurements.level.low',
        MeasurementLevel.normal => 'measurements.level.normal',
        MeasurementLevel.elevated =>
          kind == MeasurementKind.bp
              ? 'measurements.level.elevated_bp'
              : 'measurements.level.elevated_glucose',
        MeasurementLevel.high => 'measurements.level.high',
      });

  StatusTone get tone => switch (this) {
    MeasurementLevel.normal => StatusTone.success,
    MeasurementLevel.high => StatusTone.danger,
    MeasurementLevel.low || MeasurementLevel.elevated => StatusTone.attention,
  };

  IconData get icon => switch (this) {
    MeasurementLevel.low => ArrowIcons.caretDown,
    MeasurementLevel.normal => ActionIcons.check,
    MeasurementLevel.elevated => ArrowIcons.caretUp,
    MeasurementLevel.high => NoticeIcons.warning,
  };

  /// The fill of this level's part of the scale: calm below, green in the
  /// range, warm above, red when high.
  Color get scaleFill => switch (this) {
    MeasurementLevel.low => AppSemanticColors.borderPlan,
    MeasurementLevel.normal => AppSemanticColors.selectedSurface,
    MeasurementLevel.elevated => AppSemanticColors.surfaceAttention,
    MeasurementLevel.high => AppSemanticColors.surfaceDanger,
  };
}

/// A reading's level as the one status badge: «طبيعي ✓», «مرتفع ⚠».
class MeasurementLevelBadge extends StatelessWidget {
  const MeasurementLevelBadge({
    super.key,
    required this.level,
    required this.kind,
  });

  final MeasurementLevel level;
  final MeasurementKind kind;

  @override
  Widget build(BuildContext context) => StatusBadge(
    text: level.label(context, kind),
    tone: level.tone,
    icon: level.icon,
  );
}

/// [band]'s values as people read them: «70–100», «أقل من 70», «126
/// فأكثر»; blood pressure as systolic over diastolic, «90–120 / 60–80».
/// Numbers are kept left to right inside Arabic text, so «70–100» is not
/// shown as «100–70».
String normalBandText(
  BuildContext context,
  MeasurementKind kind,
  NormalBand band,
) {
  if (kind == MeasurementKind.glucose) return _glucose(context, band);
  if (band.level == MeasurementLevel.low) {
    return context.tr(
      'measurements.range_below',
      args: [_ltr('${band.systolicHigh! + 1}/${band.diastolicHigh! + 1}')],
    );
  }
  if (band.level == MeasurementLevel.high) {
    return context.tr(
      'measurements.range_from',
      args: [_ltr('${band.systolicLow}/${band.diastolicLow}')],
    );
  }
  return _ltr(normalBandNumbers(kind, band));
}

/// The numbers of a closed band with no marks around them, for a cell
/// that is set left to right already (the PDF): «70–100», «90–120 /
/// 60–80».
String normalBandNumbers(MeasurementKind kind, NormalBand band) =>
    kind == MeasurementKind.glucose
    ? '${band.glucoseLow}–${band.glucoseHigh}'
    : '${band.systolicLow}–${band.systolicHigh} / '
          '${band.diastolicLow}–${band.diastolicHigh}';

String _glucose(BuildContext context, NormalBand band) {
  final int? low = band.glucoseLow;
  final int? high = band.glucoseHigh;
  if (low == null) {
    return context.tr('measurements.range_below', args: ['${high! + 1}']);
  }
  if (high == null) {
    return context.tr('measurements.range_from', args: ['$low']);
  }
  return _ltr(normalBandNumbers(MeasurementKind.glucose, band));
}

/// [value] isolated left to right (U+2066 … U+2069).
String _ltr(String value) => '\u2066$value\u2069';

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
