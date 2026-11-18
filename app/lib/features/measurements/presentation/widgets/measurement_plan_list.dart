import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plans_empty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The list of «الخطة»'s measurements: loading, a retry when it failed, the
/// empty note, or one card for each active plan of [circleId].
class MeasurementPlanList extends StatelessWidget {
  const MeasurementPlanList({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementPlansCubit>().state;
    final List<MeasurementPlan> active = <MeasurementPlan>[
      for (final MeasurementPlan plan in state.plans)
        if (plan.stoppedAt == null) plan,
    ];
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: <Widget>[
        header,
        const SizedBox(height: AppSpacing.lg),
        if (state.status == MeasurementLoadStatus.loading &&
            state.plans.isEmpty)
          const LoadingNote()
        else if (state.status == MeasurementLoadStatus.failure)
          RetryView(
            messageKey: state.errorKey ?? 'error.unknown',
            onRetry: () => context.read<MeasurementPlansCubit>().load(circleId),
          )
        else if (active.isEmpty)
          MeasurementPlansEmpty(circleId: circleId, canManage: canManage)
        else
          for (final MeasurementPlan plan in active) ...<Widget>[
            MeasurementPlanCard(
              circleId: circleId,
              canManage: canManage,
              plan: plan,
            ),
            const SizedBox(height: AppItemCard.listGap),
          ],
      ],
    );
  }
}
