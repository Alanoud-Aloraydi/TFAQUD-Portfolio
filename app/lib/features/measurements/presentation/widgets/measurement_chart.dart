import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_legend.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:flutter/material.dart';

part 'package:app/features/measurements/presentation/widgets/measurement_chart_state.dart';

/// RTL month chart: a line of glucose dots, or a capsule per blood-pressure
/// reading. A tap near a reading shows it under the chart. A pinch, or «+»
/// and «−», spreads the days apart; a drag then moves along the month.
class MeasurementChart extends StatefulWidget {
  const MeasurementChart({
    super.key,
    required this.kind,
    required this.readings,
    required this.month,
    required this.circleId,
    this.target = const ChartTarget(<ChartBand>[]),
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final CalendarMonth month;
  final String circleId;

  /// The normal bands drawn behind the readings.
  final ChartTarget target;

  @override
  State<MeasurementChart> createState() => _MeasurementChartState();
}
