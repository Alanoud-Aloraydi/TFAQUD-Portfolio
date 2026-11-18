import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_checks.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_filling.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_layout.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_page.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_readings.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_saving.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_scope.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_bar.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_unavailable.dart';
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
    ranges = MeasurementRangesCubit(GetIt.I<MeasurementRepository>())
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
