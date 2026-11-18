import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
