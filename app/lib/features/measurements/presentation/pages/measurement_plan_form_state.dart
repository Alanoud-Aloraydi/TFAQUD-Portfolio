import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_filling.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_layout.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The state of [MeasurementPlanFormPage]: its fields, what it does with
/// them, and the page it builds, each in its own mixin.
class MeasurementPlanFormState extends State<MeasurementPlanFormPage>
    with
        MeasurementPlanFormScope,
        MeasurementPlanFormFilling,
        MeasurementPlanFormChecks,
        MeasurementPlanFormSaving,
        MeasurementPlanFormReadings,
        MeasurementPlanFormLayout {
  @override
  void initState() {
    super.initState();
    ranges = MeasurementRangesCubit(GetIt.I<MeasurementsRepository>())
      ..load(widget.circleId);
  }

  @override
  void dispose() {
    ranges.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementPlansCubit>().state;
    final MeasurementPlan? plan = editedPlan(state.plans);
    if (widget.planId != null && plan == null) {
      return MeasurementPlanFormUnavailable(
        state: state,
        circleId: widget.circleId,
      );
    }
    final MeasurementPlan? existing = plan == null
        ? activePlanOf(state.plans)
        : null;
    return Scaffold(
      appBar: measurementPlanFormBar(
        context,
        isNew: plan == null,
        onSave: saving || existing != null ? null : () => save(plan),
      ),
      body: formBody(plan, existing),
    );
  }
}

/// What the plan form shows while the plan to edit is not there: loading,
/// «حاول مرة ثانية» when it failed to load, or that it was not found.
class MeasurementPlanFormUnavailable extends StatelessWidget {
  const MeasurementPlanFormUnavailable({
    super.key,
    required this.state,
    required this.circleId,
  });

  final MeasurementPlansState state;
  final String circleId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: switch (state.status) {
        MeasurementLoadStatus.initial ||
        MeasurementLoadStatus.loading => const LoadingNote(),
        MeasurementLoadStatus.failure => TextButton(
          onPressed: () => context.read<MeasurementPlansCubit>().load(circleId),
          child: Text(context.tr(state.errorKey ?? 'error.unknown')),
        ),
        MeasurementLoadStatus.ready => Text(
          context.tr('error.resource_not_found'),
        ),
      },
    ),
  );
}
