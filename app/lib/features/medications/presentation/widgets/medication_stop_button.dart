import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_plan_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «إيقاف الدواء» at the end of the edit form: ending the treatment is a
/// change to the medicine, so it lives where the medicine is changed. Red
/// and outlined, as an action that cannot be undone; it asks first, and
/// once stopped closes the form as a saved change would.
class MedicationStopButton extends StatelessWidget {
  const MedicationStopButton({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppSizes.button),
      foregroundColor: AppSemanticColors.statusError,
      side: const BorderSide(color: AppSemanticColors.statusError),
    ),
    onPressed: () => _stop(context),
    icon: const Icon(CupertinoIcons.stop_circle, size: AppSizes.iconSmall),
    label: Text(context.tr('medications.discontinue')),
  );

  Future<void> _stop(BuildContext context) async {
    final bool stopped = await discontinueMedication(context, plan);
    if (stopped && context.mounted) context.pop(true);
  }
}
