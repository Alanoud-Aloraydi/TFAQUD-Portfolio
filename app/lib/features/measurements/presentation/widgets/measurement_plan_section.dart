import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The «الخطة» tab's measurements: the active plans of [circleId], each
/// editable and stoppable when [canManage]. The plans and tasks read again
/// by themselves after a change saved anywhere.
class MeasurementPlanSection extends StatelessWidget {
  const MeasurementPlanSection({
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
    // The normal ranges the opened details show, read once for the circle.
    return BlocProvider<MeasurementRangesCubit>(
      key: ValueKey<String>('measurement-ranges-$circleId'),
      create: (_) =>
          MeasurementRangesCubit(GetIt.I<MeasurementRepository>())
            ..load(circleId),
      child: ListView(
        padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
        children: <Widget>[
          header,
          const SizedBox(height: AppSpacing.lg),
          if (state.status == MeasurementLoadStatus.loading &&
              state.plans.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (state.status == MeasurementLoadStatus.failure)
            RetryView(
              messageKey: state.errorKey ?? 'error.unknown',
              onRetry: () =>
                  context.read<MeasurementPlansCubit>().load(circleId),
            )
          else if (active.isEmpty)
            EmptyStateNote.section(
              context.tr('measurements.no_plans'),
              actionLabel: canManage ? context.tr('add.measurement') : null,
              onAction: canManage
                  ? () => context.push(Routes.newMeasurement(circleId))
                  : null,
            )
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
      ),
    );
  }
}
