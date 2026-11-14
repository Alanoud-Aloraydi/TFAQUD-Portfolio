import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_details_content.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One medicine's page: its details, versions, pending change and dose
/// history. Opened from the plan, record and «اليوم» rows with `extra`
/// [canManage]; the route builds its [MedicationsCubit] (`loadPlan`).
class MedicationDetailsPage extends StatelessWidget {
  const MedicationDetailsPage({
    super.key,
    required this.circleId,
    required this.planId,
    required this.canManage,
  });

  final String circleId;
  final String planId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          // The page keeps its bar while it loads, so only the content
          // changes when it comes.
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('medications.details'))),
            body: const MedicationDetailsSkeleton(),
          );
        }
        if (state.status == MedicationsStatus.failure || state.plans.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: RetryView(
              messageKey: state.messageKey ?? 'error.resource_not_found',
              onRetry: () =>
                  context.read<MedicationsCubit>().loadPlan(circleId, planId),
            ),
          );
        }
        return MedicationDetailsContent(
          key: ValueKey(state.plans.first.version.number),
          circleId: circleId,
          plan: state.plans.first,
          canManage: canManage,
        );
      },
    );
  }
}
