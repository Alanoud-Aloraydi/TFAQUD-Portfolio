import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicine.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The current medicines: the name and strength at the start, the dose
/// times at the end.
class EmergencyMedicines extends StatelessWidget {
  const EmergencyMedicines({super.key, required this.words});

  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (BuildContext context, MedicationsState state) {
        final DateTime today = PatientClockScope.of(context).today();
        final List<MedicationPlan> current = state.plans
            .where(
              (MedicationPlan plan) =>
                  !plan.isPreviousOn(today) && !plan.isScheduledOn(today),
            )
            .toList();
        final Widget content;
        if (state.status == MedicationsStatus.loading ||
            state.status == MedicationsStatus.initial) {
          content = const CupertinoActivityIndicator();
        } else if (state.status == MedicationsStatus.failure) {
          content = TextButton(
            onPressed: () => context.read<MedicationsCubit>().load(
              context.read<EmergencyCardCubit>().circleId,
            ),
            child: Text(context.tr(state.messageKey ?? 'error.unknown')),
          );
        } else if (current.isEmpty) {
          content = Text(
            words.t('no_current_medications'),
            style: text.titleSmall,
          );
        } else {
          content = Column(
            children: <Widget>[
              for (final MedicationPlan plan in current) ...<Widget>[
                if (plan != current.first)
                  const SizedBox(height: AppSpacing.sm),
                EmergencyMedicine(plan: plan, words: words),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              words.t('current_medications'),
              style: text.labelLarge?.copyWith(
                color: AppSemanticColors.textSupporting,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            content,
          ],
        );
      },
    );
  }
}
