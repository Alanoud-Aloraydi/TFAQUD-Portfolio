import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_stop_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The end of the medication form: why it could not be saved ([errorKey]),
/// then, when an existing medicine is edited ([plan]), «إيقاف الدواء».
class MedicationFormFooter extends StatelessWidget {
  const MedicationFormFooter({super.key, this.errorKey, this.plan});

  final String? errorKey;
  final MedicationPlan? plan;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (errorKey case final String error) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr(error),
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      if (plan case final MedicationPlan plan) ...<Widget>[
        const SizedBox(height: AppSpacing.xl),
        MedicationStopButton(plan: plan),
      ],
      const SizedBox(height: AppSpacing.xl),
    ],
  );
}
