import 'dart:async';

import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Opens «سجّل جرعة الآن» for [circleId]. True when a dose was saved.
Future<bool> showExtraDoseSheet(
  BuildContext context, {
  required String circleId,
}) async =>
    await showGlassSheet<bool>(
      context,
      title: context.tr('add.dose_now'),
      builder: (_) => BlocProvider(
        create: (_) =>
            ExtraDoseCubit(GetIt.I<MedicationsUseCase>(), circleId)..load(),
        child: const ExtraDoseSheet(),
      ),
    ) ??
    false;

/// «سجّل جرعة الآن»: the medicines still taken today to choose from, then
/// the dose and its time. Always one more dose: it never answers a dose
/// time.
class ExtraDoseSheet extends StatelessWidget {
  const ExtraDoseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ExtraDoseCubit cubit = context.read<ExtraDoseCubit>();
    final DateTime today = PatientClockScope.of(context).today();
    return BlocBuilder<ExtraDoseCubit, ExtraDoseState>(
      buildWhen: (before, after) =>
          before.plans != after.plans ||
          before.loadErrorKey != after.loadErrorKey,
      builder: (BuildContext context, ExtraDoseState state) {
        final String? failed = state.loadErrorKey;
        if (failed != null) {
          return RetryView(messageKey: failed, onRetry: cubit.load);
        }
        final List<MedicationPlan>? plans = state.plans
            ?.where((plan) => plan.statusOn(today) == PlanStatus.active)
            .toList();
        if (plans == null) return const LoadingNote();
        if (plans.isEmpty) return ExtraDoseEmpty(circleId: cubit.circleId);
        return ExtraDoseForm(circleId: cubit.circleId, plans: plans);
      },
    );
  }
}

/// «سجّل جرعة الآن» with no medicine taken today: the way to add one.
class ExtraDoseEmpty extends StatelessWidget {
  const ExtraDoseEmpty({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) => EmptyStateNote(
    context.tr('medications.dose_now_empty'),
    actionLabel: context.tr('add.medication'),
    onAction: () {
      final GoRouter router = GoRouter.of(context);
      Navigator.of(context).pop(false);
      unawaited(router.push<bool>(CareItemRoutes.newMedication(circleId)));
    },
  );
}
