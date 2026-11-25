import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/domain/entities/measurement_conditions.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The rows of every reading of a plan: its time, then its «حالة القياس»,
/// and «إضافة قراءة» ([onAdd]) while more may be added. [onEdit] runs a
/// change and clears the error shown; [errorKey] «times_repeat» is said
/// under each of the same times.
List<Widget> planReadingRows({
  required List<PlanReadingDraft> readings,
  required MeasurementKind kind,
  required String? errorKey,
  required void Function(VoidCallback change) onEdit,
  required VoidCallback onAdd,
}) => <Widget>[
  for (int index = 0; index < readings.length; index++) ...[
    PlanReadingTimeRow(
      readings: readings,
      index: index,
      repeated: errorKey == 'measurements.times_repeat',
      onEdit: onEdit,
    ),
    PlanReadingStateBlock(
      readings: readings,
      index: index,
      kind: kind,
      onEdit: onEdit,
    ),
  ],
  if (readings.length < PlanScheduleDraft.maxReadings)
    PlanAddReadingRow(onAdd: onAdd),
];

/// «إضافة قراءة»: one more reading time in the plan.
class PlanAddReadingRow extends StatelessWidget {
  const PlanAddReadingRow({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => InsetRow(
    label: context.tr('measurements.add_reading'),
    leading: const Icon(ActionIcons.plusCircle),
    onTap: onAdd,
  );
}

/// «حالة القياس» of reading [index] of a plan: the chips of its kind.
/// [onEdit] runs a change and clears the error shown.
class PlanReadingStateBlock extends StatelessWidget {
  const PlanReadingStateBlock({
    super.key,
    required this.readings,
    required this.index,
    required this.kind,
    required this.onEdit,
  });

  final List<PlanReadingDraft> readings;
  final int index;
  final MeasurementKind kind;
  final void Function(VoidCallback change) onEdit;

  @override
  Widget build(BuildContext context) {
    final PlanReadingDraft reading = readings[index];
    final String label = planReadingLabel(context, readings.length, index);
    return InsetBlock(
      semanticLabel: '$label، ${context.tr('measurements.state')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('measurements.state'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          OptionChips(
            options: [
              for (final value in MeasurementConditions.planStates(kind))
                ChipOption(value, context.tr('measurements.condition.$value')),
            ],
            isSelected: (value) => reading.measurementState == value,
            onTap: (value) => onEdit(() => reading.measurementState = value),
          ),
        ],
      ),
    );
  }
}

/// «القراءة 2» when there are several readings, «الوقت» for a single one.
String planReadingLabel(BuildContext context, int count, int index) =>
    count == 1
    ? context.tr('measurements.time')
    : context.tr('measurements.reading_number', args: ['${index + 1}']);

/// The time of reading [index] of a plan, and «حذف» for all but a single
/// reading. [onEdit] runs a change and clears the error shown.
class PlanReadingTimeRow extends StatelessWidget {
  const PlanReadingTimeRow({
    super.key,
    required this.readings,
    required this.index,
    required this.repeated,
    required this.onEdit,
  });

  final List<PlanReadingDraft> readings;
  final int index;

  /// The form was refused for two same times: said under each of them.
  final bool repeated;
  final void Function(VoidCallback change) onEdit;

  @override
  Widget build(BuildContext context) {
    final PlanReadingDraft reading = readings[index];
    final String label = planReadingLabel(context, readings.length, index);
    final bool same =
        repeated &&
        readings.where((item) => item.time == reading.time).length > 1;
    return InsetRow(
      label: label,
      value: timeOfDayText(reading.time),
      errorText: same ? context.tr('measurements.times_repeat') : null,
      trailing: readings.length == 1
          ? null
          : IconButton(
              tooltip: context.tr(
                'measurements.remove_reading',
                args: ['${index + 1}'],
              ),
              icon: const Icon(ActionIcons.trash),
              onPressed: () => onEdit(() => readings.removeAt(index)),
            ),
      onTap: () async {
        final selected = await showTafaqodTimeSheet(
          context,
          title: label,
          initialTime: reading.time,
        );
        if (selected != null && context.mounted) {
          onEdit(() => reading.time = selected);
        }
      },
    );
  }
}
