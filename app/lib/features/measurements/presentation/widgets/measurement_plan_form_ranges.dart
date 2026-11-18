import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/models/plan_reading_draft.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_ranges_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «المعدل الطبيعي» of the plan form: fixed by the meal states of the
/// [readings] and the medical file, shown, not typed.
class MeasurementPlanFormRanges extends StatelessWidget {
  const MeasurementPlanFormRanges({
    super.key,
    required this.cubit,
    required this.circleId,
    required this.kind,
    required this.readings,
  });

  final MeasurementRangesCubit cubit;
  final String circleId;
  final MeasurementKind kind;
  final List<PlanReadingDraft> readings;

  @override
  Widget build(BuildContext context) =>
      BlocProvider<MeasurementRangesCubit>.value(
        value: cubit,
        child: MeasurementRangesBox(
          circleId: circleId,
          kind: kind,
          states: <String?>[for (final item in readings) item.measurementState],
        ),
      );
}
