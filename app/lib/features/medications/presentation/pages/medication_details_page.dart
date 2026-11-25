import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_history_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_details_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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

/// A medicine's page while it loads: the name and strength, the details
/// card, and the dose times.
class MedicationDetailsSkeleton extends StatelessWidget {
  const MedicationDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      children: <Widget>[
        SkeletonLine(widthFactor: 0.55, height: 24),
        SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: 0.3),
        SizedBox(height: AppSpacing.lg),
        SkeletonSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonLabelValue(valueWidth: 0.5),
              SizedBox(height: AppSpacing.md),
              SkeletonLabelValue(valueWidth: 0.4),
              SizedBox(height: AppSpacing.md),
              SkeletonLabelValue(valueWidth: 0.6),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.3, height: 20),
        SizedBox(height: AppSpacing.md),
        SkeletonLabelValue(valueWidth: 0.45),
        SizedBox(height: AppSpacing.md),
        SkeletonLabelValue(valueWidth: 0.45),
      ],
    );
  }
}

class SkeletonLabelValue extends StatelessWidget {
  const SkeletonLabelValue({super.key, required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SkeletonLine(widthFactor: 0.25, height: 12),
        const SizedBox(height: AppSpacing.sm),
        SkeletonLine(widthFactor: valueWidth, height: 16),
      ],
    );
  }
}

/// The medicine's page: its own month of doses loaded beside it, and its
/// extra doses.
class MedicationDetailsContent extends StatelessWidget {
  const MedicationDetailsContent({
    super.key,
    required this.circleId,
    required this.plan,
    required this.canManage,
  });

  final String circleId;
  final MedicationPlan plan;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final today = PatientClockScope.of(context).today();
    // Calendar days, so a phone's own DST change never moves the range.
    final from = DateTime(today.year, today.month, today.day - 31);
    final start = plan.version.startsOn.isAfter(from)
        ? plan.version.startsOn
        : from;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MedicationOccurrencesCubit(
            GetIt.I<MedicationsUseCase>(),
            photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
          )..load(circleId, start, today, planId: plan.id),
        ),
        BlocProvider(
          create: (_) =>
              ExtraDoseHistoryCubit(GetIt.I<MedicationsUseCase>())
                ..load(circleId, plan.id, today),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medications.details')),
          actions: [
            if (canManage && !plan.isPreviousOn(today))
              EditAction.pen(
                tooltip: context.tr('medications.edit_title'),
                onPressed: () => editMedication(context, circleId, plan.id),
              ),
          ],
        ),
        body: MedicationDetailsBody(
          circleId: circleId,
          plan: plan,
          canManage: canManage,
        ),
      ),
    );
  }
}

/// Opens the medicine's form and, when it saved, closes the medicine's page
/// with it, so the list behind both is reloaded once.
Future<void> editMedication(
  BuildContext context,
  String circleId,
  String planId,
) async {
  final changed = await context.push<bool>(
    CareItemRoutes.editMedication(circleId, planId),
  );
  if (changed == true && context.mounted) {
    context.pop(true);
  }
}
