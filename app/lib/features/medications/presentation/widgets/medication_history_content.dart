import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_list.dart';
import 'package:app/features/medications/presentation/widgets/plans_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What «السجل» holds for one state of the medicines cubit: the skeleton,
/// the retry view, or the medicines already behind.
class MedicationHistoryContent extends StatelessWidget {
  const MedicationHistoryContent({
    super.key,
    required this.circleId,
    required this.header,
    required this.state,
  });

  final String circleId;
  final Widget header;
  final MedicationsState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == MedicationsStatus.initial ||
        state.status == MedicationsStatus.loading) {
      return const PlansSkeleton(filter: false);
    }
    if (state.status == MedicationsStatus.failure) {
      return RetryView(
        messageKey: state.messageKey!,
        onRetry: () => context.read<MedicationsCubit>().load(circleId),
      );
    }
    final DateTime today = PatientClockScope.of(context).today();
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        // «السجل» is what has been: only the medicines already behind.
        // «الخطة» is where the running ones live, so a filter here would
        // offer a choice with nothing in it.
        ...medicationRecordList(
          context,
          circleId: circleId,
          plans: state.plans.where((plan) => plan.isPreviousOn(today)).toList(),
        ),
      ],
    );
  }
}
