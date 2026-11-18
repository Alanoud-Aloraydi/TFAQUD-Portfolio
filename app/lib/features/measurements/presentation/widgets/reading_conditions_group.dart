import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
