import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_checks.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Saves the plan the form describes.
mixin MeasurementPlanFormSaving
    on MeasurementPlanFormScope, MeasurementPlanFormChecks {
  Future<void> save(MeasurementPlan? plan) async {
    if (!isReady(plan)) return;
    final draft = _draft();
    setState(() {
      saving = true;
      errorKey = null;
    });
    final cubit = context.read<MeasurementPlansCubit>();
    final String? failure = plan == null
        ? await cubit.create(draft)
        : await cubit.revise(plan, draft);
    if (!mounted) return;
    if (failure == null) {
      AppToast.show(context, 'toast.measurement_plan_saved');
      context.pop(true);
    } else {
      setState(() => saving = false);
      _refused(failure);
    }
  }

  /// A refusal that belongs to a row is said under it; any other is a toast.
  void _refused(String key) =>
      key == 'measurements.days_required' || key == 'measurements.times_repeat'
      ? setState(() => errorKey = key)
      : AppToast.show(context, key, kind: ToastKind.error);

  MeasurementPlanDraft _draft() {
    final sorted = readings.toList()
      ..sort((a, b) => a.clock.compareTo(b.clock));
    return MeasurementPlanDraft(
      kind: kind,
      times: <MeasurementTime>[
        for (final item in sorted)
          MeasurementTime(
            time: item.clock,
            measurementState: item.measurementState,
          ),
      ],
      weekdays: days.toList()..sort(),
      startsOn: start,
      missedAfterMinutes: missedAfter!,
    );
  }
}
