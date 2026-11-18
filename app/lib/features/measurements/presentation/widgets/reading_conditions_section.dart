import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/widgets/reading_conditions_group.dart';
import 'package:app/features/measurements/presentation/widgets/reading_other_condition.dart';
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
