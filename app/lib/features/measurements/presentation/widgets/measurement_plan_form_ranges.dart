import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_history.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// «المعدل الطبيعي» of a plan, from the [MeasurementRangesCubit] above: one
/// card per range its readings are judged by (glucose: fasting and after a
/// meal, as its reading [states] need), then where the condition comes from
/// and a row to change it in the medical file.
class MeasurementRangesBox extends StatelessWidget {
  const MeasurementRangesBox({
    super.key,
    required this.circleId,
    required this.kind,
    this.states = const <String?>[],
  });

  final String circleId;
  final MeasurementKind kind;

  /// The planned meal states of a glucose plan's reading times; none shows
  /// both glucose ranges.
  final List<String?> states;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MeasurementRangesCubit, MeasurementRangesState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final NormalRanges? ranges = state.ranges;
          if (ranges == null) {
            // Tapping the message reads them again, as the lists retry.
            return TextButton(
              onPressed: () =>
                  context.read<MeasurementRangesCubit>().load(circleId),
              child: Text(context.tr(state.errorKey ?? 'error.unknown')),
            );
          }
          return MeasurementRangeCards(
            circleId: circleId,
            ranges: <NormalRange>[
              if (kind == MeasurementKind.bp)
                ?ranges.of(MeasurementKind.bp)
              else
                for (final String group in _groups())
                  ?ranges.of(MeasurementKind.glucose, group),
            ],
          );
        },
      );

  /// The glucose tables [states] need, fasting first; both when none.
  List<String> _groups() {
    final Set<String> used = {
      for (final String? state in states) normalRangeState(state),
    };
    return <String>[
      for (final String group in const <String>['fasting', 'after_meal'])
        if (used.isEmpty || used.contains(group)) group,
    ];
  }
}
