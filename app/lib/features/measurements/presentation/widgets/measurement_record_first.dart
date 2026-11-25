import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// «الخطة»'s measurements: the active plans of [circleId], editable and
/// stoppable when [canManage], read again after a change saved anywhere.
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
    // The normal ranges the opened details show, read once for the circle.
    return BlocProvider<MeasurementRangesCubit>(
      key: ValueKey<String>('measurement-ranges-$circleId'),
      create: (_) =>
          MeasurementRangesCubit(GetIt.I<MeasurementsRepository>())
            ..load(circleId),
      child: MeasurementPlanList(
        circleId: circleId,
        canManage: canManage,
        header: header,
      ),
    );
  }
}

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

/// «ما في قياسات»: nothing planned yet, with «إضافة قياس» for someone who
/// can manage the plans.
class MeasurementPlansEmpty extends StatelessWidget {
  const MeasurementPlansEmpty({
    super.key,
    required this.circleId,
    required this.canManage,
  });

  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('measurements.no_plans'),
    actionLabel: canManage ? context.tr('add.measurement') : null,
    onAction: canManage
        ? () => context.push(CareItemRoutes.newMeasurement(circleId))
        : null,
  );
}
