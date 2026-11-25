import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicine_times.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What sits under «الأدوية الحالية»: the turning circle while the plans
/// load, a retry when they could not be read, the line that says there are
/// none, else one row per medicine.
Widget emergencyMedicinesContent(
  BuildContext context, {
  required MedicationsState state,
  required List<MedicationPlan> current,
  required EmergencyCardText words,
}) {
  if (state.status == MedicationsStatus.loading ||
      state.status == MedicationsStatus.initial) {
    return const LoadingNote();
  }
  if (state.status == MedicationsStatus.failure) {
    return TextButton(
      onPressed: () => context.read<MedicationsCubit>().load(
        context.read<EmergencyCardCubit>().circleId,
      ),
      child: Text(context.tr(state.messageKey ?? 'error.unknown')),
    );
  }
  if (current.isEmpty) {
    return Text(
      words.t('no_current_medications'),
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
  return Column(
    children: <Widget>[
      for (final MedicationPlan plan in current) ...<Widget>[
        if (plan != current.first) const SizedBox(height: AppSpacing.sm),
        EmergencyMedicine(plan: plan, words: words),
      ],
    ],
  );
}

/// One medicine on the emergency card: what it is at the start, when it is
/// taken at the end.
class EmergencyMedicine extends StatelessWidget {
  const EmergencyMedicine({super.key, required this.plan, required this.words});

  final MedicationPlan plan;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppSemanticColors.textSupporting);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: EmergencyMedicineName(
                plan: plan,
                words: words,
                small: small,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            EmergencyMedicineTimes(plan: plan, words: words, small: small),
          ],
        ),
      ),
    );
  }
}
