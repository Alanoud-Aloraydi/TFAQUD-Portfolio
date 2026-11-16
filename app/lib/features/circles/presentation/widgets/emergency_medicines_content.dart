import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicine.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
    return const CupertinoActivityIndicator();
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
