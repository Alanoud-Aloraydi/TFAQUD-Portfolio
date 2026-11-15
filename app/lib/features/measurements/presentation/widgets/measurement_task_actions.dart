import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/buttons/task_button_grid.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «تسجيل قراءة» and «تخطي» under a measurement row that can still be
/// answered, in the buttons every task shares (TaskButtonRole). Once the
/// next task of its kind is due ([superseded]) a reading would answer that
/// one, so only «تخطي» stays, under the reason ([sayWhy]: false where the
/// card says it already).
class MeasurementTaskActions extends StatelessWidget {
  const MeasurementTaskActions({
    super.key,
    required this.task,
    this.superseded = false,
    this.sayWhy = true,
  });

  final MeasurementOccurrence task;
  final bool superseded;
  final bool sayWhy;

  @override
  Widget build(BuildContext context) {
    final Widget buttons = TaskButtonGrid(
      buttons: <Widget>[
        if (!superseded)
          TaskButton(
            role: TaskButtonRole.answer,
            icon: CupertinoIcons.checkmark,
            label: context.tr('measurements.record_reading'),
            onPressed: () =>
                showMeasurementReadingSheet(context, occurrence: task),
          ),
        TaskButton(
          role: TaskButtonRole.skip,
          icon: CupertinoIcons.minus_circle,
          label: context.tr('measurements.skip'),
          onPressed: () => skipMeasurement(context, task),
        ),
      ],
    );
    if (!superseded || !sayWhy) return buttons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.tr('measurements.superseded'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        buttons,
      ],
    );
  }
}
