import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/reading_extras.dart';
import 'package:app/features/measurements/presentation/widgets/reading_status_pill.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

/// One glucose or blood pressure reading, the same everywhere it is listed:
/// the kind and when, the value with its unit, where it stands against the
/// target, then the details. At large text sizes the value drops under the
/// title instead of squeezing it.
class MeasurementReadingTile extends StatelessWidget {
  const MeasurementReadingTile({
    super.key,
    required this.reading,
    required this.circleId,
  });

  final MeasurementReading reading;
  final String circleId;

  static const double stackedScale = 1.3;

  bool get _skipped => reading.outcome == 'skipped';

  BoxDecoration get _decoration => BoxDecoration(
    color: reading.outsideTarget == true
        ? AppSemanticColors.surfaceAttention
        : AppSemanticColors.surfaceContent,
    border: Border.all(color: AppSemanticColors.borderSubtle),
    borderRadius: BorderRadius.circular(AppRadius.field),
  );

  Widget _header({required bool inline, required Widget value}) => Row(
    children: <Widget>[
      Icon(
        reading.kind == MeasurementKind.glucose
            ? CupertinoIcons.drop
            : CupertinoIcons.heart,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: ReadingTitles(reading: reading)),
      if (inline) value,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final bool stacked =
        MediaQuery.textScalerOf(context).scale(1) > stackedScale;
    final Widget value = ReadingValue(reading: reading);
    return DecoratedBox(
      decoration: _decoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(inline: !stacked && !_skipped, value: value),
            if (stacked && !_skipped) value,
            const SizedBox(height: AppSpacing.sm),
            _skipped
                ? Text(context.tr('measurements.skipped'))
                : ReadingStatusPill(reading: reading),
            ReadingExtras(reading: reading, circleId: circleId),
          ],
        ),
      ),
    );
  }
}
