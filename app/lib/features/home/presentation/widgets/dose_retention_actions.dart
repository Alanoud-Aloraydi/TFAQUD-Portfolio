import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/home/presentation/cubit/dose_retention_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_header.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the warning before doses are deleted says, and its two answers.
/// An export holds every dose until today, so the warning waits for the
/// doses after it; «لاحقًا» waits five days.
class DoseRetentionActions extends StatelessWidget {
  const DoseRetentionActions({
    super.key,
    required this.circleId,
    required this.through,
  });

  final String circleId;

  /// The last day whose doses go within five days.
  final DateTime through;

  Future<void> _export(BuildContext context) async {
    final DoseRetentionCubit cubit = context.read<DoseRetentionCubit>();
    final DateTime today = PatientClockScope.of(context).today();
    await showRecordExportSheet(
      context,
      circleId: circleId,
      plans: context.read<MedicationsCubit>().state.plans,
      measurementPlans: context.read<MeasurementPlansCubit>().state.plans,
    );
    await cubit.settle(today);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.tr(
          'dose_retention.body',
          args: <String>[formatMedicationDate(context, through)],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: () => _export(context),
        child: Text(context.tr('dose_retention.export')),
      ),
      TextButton(
        onPressed: () => context.read<DoseRetentionCubit>().settle(
          DoseRetention.laterThrough(through),
        ),
        child: Text(context.tr('dose_retention.later')),
      ),
    ],
  );
}
