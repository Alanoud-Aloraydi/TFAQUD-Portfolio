import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The lines under a reading: its conditions, the reason it was skipped, the
/// note and who recorded it. Each one shows only when it has something.
class ReadingExtras extends StatelessWidget {
  const ReadingExtras({
    super.key,
    required this.reading,
    required this.circleId,
  });

  final MeasurementReading reading;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.tokens.textSecondary);
    final bool skipped = reading.outcome == 'skipped';
    final String? name = reading.recordedByName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!skipped &&
            reading.planVersionId == null &&
            reading.outsideTarget != null)
          Text(
            '${context.tr('measurements.target')}: ${reading.targetText}',
            style: style,
          ),
        if (!skipped && reading.conditions.isNotEmpty)
          Text(readingConditionsText(context, reading), style: style),
        if (skipped && reading.skipReasonCode != null)
          Text(
            context.tr(
              'measurements.skip_reason_line',
              args: <String>[measurementSkipReasonText(context, reading)],
            ),
            style: style,
          ),
        if (reading.note != null) Text(reading.note!, style: style),
        if (name != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PersonPhoto(
                name: name,
                photoPath: personPhotoPath(
                  circleId,
                  reading.recordedByAccountId,
                ),
                avatarCode: reading.recordedByAvatarCode,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSpacing.tight),
              Flexible(child: Text(name, style: style)),
            ],
          ),
        ],
      ],
    );
  }
}
