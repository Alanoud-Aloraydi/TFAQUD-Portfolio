import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicines_content.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The current medicines: the name and strength at the start, the dose
/// times at the end.
class EmergencyMedicines extends StatelessWidget {
  const EmergencyMedicines({super.key, required this.words});

  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MedicationsCubit, MedicationsState>(
        builder: (BuildContext context, MedicationsState state) {
          final DateTime today = PatientClockScope.of(context).today();
          final List<MedicationPlan> current = state.plans
              .where(
                (MedicationPlan plan) =>
                    !plan.isPreviousOn(today) && !plan.isScheduledOn(today),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                words.t('current_medications'),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppSemanticColors.textSupporting),
              ),
              const SizedBox(height: AppSpacing.sm),
              emergencyMedicinesContent(
                context,
                state: state,
                current: current,
                words: words,
              ),
            ],
          );
        },
      );
}
