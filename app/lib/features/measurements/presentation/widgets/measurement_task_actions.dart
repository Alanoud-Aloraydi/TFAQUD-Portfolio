import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «تسجيل قراءة» and «تخطي» under a measurement row that can still be
/// answered, as tall as every other button (48). Once the next task of its
/// kind is due ([superseded]) a reading would answer that one, so only
/// «تخطي» stays, with the reason.
class MeasurementTaskActions extends StatelessWidget {
  const MeasurementTaskActions({
    super.key,
    required this.task,
    this.superseded = false,
  });

  final MeasurementOccurrence task;
  final bool superseded;

  @override
  Widget build(BuildContext context) {
    const Size tall = Size(0, AppItemCard.touch);
    return Row(
      children: <Widget>[
        Expanded(
          child: superseded
              ? Text(
                  context.tr('measurements.superseded'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: tall),
                  onPressed: () =>
                      showMeasurementReadingSheet(context, occurrence: task),
                  icon: const Icon(CupertinoIcons.checkmark),
                  label: Text(context.tr('measurements.record_reading')),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: tall),
          onPressed: () => skipMeasurement(context, task),
          icon: const Icon(CupertinoIcons.minus_circle),
          label: Text(context.tr('measurements.skip')),
        ),
      ],
    );
  }
}
