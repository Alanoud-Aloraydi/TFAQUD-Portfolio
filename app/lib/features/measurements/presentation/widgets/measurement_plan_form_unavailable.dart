import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
