import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The conditions of the reading sheet, and «أخرى» in the reader's own
/// words once it is chosen, as the medical file's «أخرى» takes them.
class ReadingConditionsSection extends StatelessWidget {
  const ReadingConditionsSection({
    super.key,
    required this.kind,
    required this.selected,
    required this.otherController,
    required this.maxLength,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final List<String> selected;
  final TextEditingController otherController;
  final int maxLength;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadingConditionsGroup(
        kind: kind,
        selected: selected,
        onChanged: onChanged,
      ),
      if (selected.contains('other')) ...[
        const SizedBox(height: AppSpacing.md),
        ReadingOtherCondition(
          controller: otherController,
          maxLength: maxLength,
        ),
      ],
    ],
  );
}

/// «أخرى» of a reading's conditions, in the reader's own words.
class ReadingOtherCondition extends StatelessWidget {
  const ReadingOtherCondition({
    super.key,
    required this.controller,
    required this.maxLength,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) => LabeledTextField(
    label: context.tr('measurements.other_condition'),
    helperText: context.tr('measurements.other_condition_hint'),
    controller: controller,
    maxLength: maxLength,
    textInputAction: TextInputAction.done,
    onChanged: (_) {},
  );
}

/// «ظروف القياس (اختياري)» of the reading sheet: the chips of its kind.
class ReadingConditionsGroup extends StatelessWidget {
  const ReadingConditionsGroup({
    super.key,
    required this.kind,
    required this.selected,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => InsetGroup(
    header: context.tr('measurements.condition_optional'),
    children: [
      InsetBlock(
        semanticLabel: context.tr('measurements.condition_optional'),
        child: MeasurementConditionChips(
          kind: kind,
          selected: selected,
          caption: context.tr('measurements.conditions_hint'),
          onChanged: onChanged,
        ),
      ),
    ],
  );
}
