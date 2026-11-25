import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the medication form page UI.
class MedicationFormPage extends StatelessWidget {
  const MedicationFormPage({super.key, required this.circleId, this.planId});

  final String circleId;
  final String? planId;

  @override
  Widget build(BuildContext context) {
    if (planId == null) return MedicationForm(circleId: circleId);
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('medications.edit_title'))),
            body: const MedicationFormSkeleton(),
          );
        }
        if (state.status == MedicationsStatus.failure || state.plans.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: RetryView(
              messageKey: state.messageKey ?? 'error.resource_not_found',
              onRetry: () =>
                  context.read<MedicationsCubit>().loadPlan(circleId, planId!),
            ),
          );
        }
        final plan = state.plans.first;
        return MedicationForm(
          key: ValueKey(plan.id),
          circleId: circleId,
          plan: plan,
        );
      },
    );
  }
}

/// The medicine form while the medicine loads for editing: its three
/// grouped sections, as `FormGroup` draws them.
class MedicationFormSkeleton extends StatelessWidget {
  const MedicationFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonFormGroup(rows: 5),
        SizedBox(height: AppSpacing.xl),
        SkeletonFormGroup(rows: 2),
        SizedBox(height: AppSpacing.xl),
        SkeletonFormGroup(rows: 4),
      ],
    );
  }
}
