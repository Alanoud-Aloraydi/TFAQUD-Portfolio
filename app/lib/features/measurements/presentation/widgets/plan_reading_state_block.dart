import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/features/measurements/domain/measurement_conditions.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/models/plan_reading_draft.dart';
import 'package:app/features/measurements/presentation/widgets/plan_reading_time_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
