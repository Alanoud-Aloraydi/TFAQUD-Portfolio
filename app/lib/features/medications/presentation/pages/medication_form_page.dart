import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_form.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationFormPage extends StatelessWidget {
  const MedicationFormPage({super.key, required this.circleId, this.planId});

  final String circleId;
  final String? planId;

  @override
  Widget build(BuildContext context) {
    if (planId == null) return const MedicationForm();
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          return const Scaffold(body: LoadingWidget());
        }
        if (state.status == MedicationsStatus.failure || state.plans.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: MedicationFailureView(
              messageKey: state.messageKey ?? 'error.resource_not_found',
              onRetry: () =>
                  context.read<MedicationsCubit>().loadPlan(circleId, planId!),
            ),
          );
        }
        final plan = state.plans.first;
        return MedicationForm(key: ValueKey(plan.version.number), plan: plan);
      },
    );
  }
}
