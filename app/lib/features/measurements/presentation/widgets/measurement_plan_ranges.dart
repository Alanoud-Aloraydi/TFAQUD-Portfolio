import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «المعدل الطبيعي» of a plan's readings, from the section's
/// [MeasurementRangesCubit]: one line per range (glucose: per meal state
/// its times use). Nothing while the ranges load or fail; the reading
/// sheet shows them too.
class MeasurementPlanRanges extends StatelessWidget {
  const MeasurementPlanRanges({super.key, required this.plan});

  final MeasurementPlan plan;

  @override
  Widget build(BuildContext context) {
    final NormalRanges? ranges = context
        .watch<MeasurementRangesCubit>()
        .state
        .ranges;
    if (ranges == null) return const SizedBox.shrink();
    final MeasurementKind kind = plan.kind;
    final List<NormalRange> shown = kind == MeasurementKind.bp
        ? <NormalRange>[?ranges.of(kind)]
        : <NormalRange>[
            for (final String group in <String>{
              for (final MeasurementTime item in plan.version.readingTimes)
                normalRangeState(item.measurementState),
            })
              ?ranges.of(kind, group),
          ];
    return PlanFactGroup(
      title: context.tr('measurements.normal_range'),
      children: <Widget>[
        for (final NormalRange range in shown)
          PlanFact(
            icon: kind == MeasurementKind.bp
                ? CareIcons.heartbeat
                : CareIcons.drop,
            label: normalRangeCaption(
              context,
              kind,
              range.profile,
              range.state,
            ),
            value:
                '${normalBandText(context, kind, range.normal)} '
                '${context.tr(kind == MeasurementKind.bp ? 'measurements.bp_unit' : 'measurements.glucose_unit')}',
          ),
      ],
    );
  }
}
