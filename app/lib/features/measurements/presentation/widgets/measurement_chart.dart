import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/chart_legend.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_painter.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:flutter/material.dart';

/// RTL month chart: a line of glucose dots, or a capsule per blood-pressure
/// reading. A tap near a reading shows it under the chart.
class MeasurementChart extends StatefulWidget {
  const MeasurementChart({
    super.key,
    required this.kind,
    required this.readings,
    required this.month,
    required this.circleId,
    this.targetLow,
    this.targetHigh,
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final DateTime month;
  final String circleId;
  final int? targetLow;
  final int? targetHigh;

  @override
  State<MeasurementChart> createState() => _MeasurementChartState();
}

class _MeasurementChartState extends State<MeasurementChart> {
  static const double _height = 176;
  static const double _reachX = 22;
  static const double _reachY = 18;

  MeasurementReading? _selected;

  @override
  void didUpdateWidget(MeasurementChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null &&
        !widget.readings.any((item) => item.id == _selected!.id)) {
      _selected = null;
    }
  }

  void _select(TapDownDetails details, double width) {
    final ChartScale scale = ChartScale.of(
      Size(width, _height),
      widget.month,
      widget.readings,
      widget.targetHigh,
      targetLow: widget.targetLow,
      kind: widget.kind,
    );
    final byDay = readingsByDay(
      widget.readings,
      widget.month,
      PatientClockScope.of(context),
    );
    MeasurementReading? nearest;
    double distance = double.infinity;
    for (final entry in byDay.entries) {
      for (int index = 0; index < entry.value.length; index++) {
        final MeasurementReading reading = entry.value[index];
        final double dx =
            (scale.center(entry.key, index, entry.value.length) -
                    details.localPosition.dx)
                .abs();
        final double dy = _verticalMiss(
          scale,
          reading,
          details.localPosition.dy,
        );
        if (dx + dy < distance && dx <= _reachX && dy <= _reachY) {
          nearest = reading;
          distance = dx + dy;
        }
      }
    }
    setState(() => _selected = nearest);
  }

  double _verticalMiss(ChartScale scale, MeasurementReading r, double dy) {
    final double first = scale.y(r.valueOne!);
    // A glucose reading is a dot; a pressure reading is the capsule
    // between its two numbers.
    final double second = widget.kind == MeasurementKind.glucose
        ? first
        : scale.y(r.valueTwo!);
    final double top = first < second ? first : second;
    final double bottom = first < second ? second : first;
    return dy < top ? top - dy : (dy > bottom ? dy - bottom : 0);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _select(details, constraints.maxWidth),
          child: SizedBox(
            height: _height,
            child: CustomPaint(
              painter: MeasurementPainter(
                widget.kind,
                widget.readings,
                widget.month,
                widget.targetLow,
                widget.targetHigh,
                PatientClockScope.of(context),
              ),
            ),
          ),
        ),
      ),
      if (_selected case final reading?) ...<Widget>[
        const SizedBox(height: AppSpacing.sm),
        MeasurementReadingTile(reading: reading, circleId: widget.circleId),
      ],
      const SizedBox(height: AppSpacing.sm),
      ChartLegend(
        kind: widget.kind,
        hasTarget: widget.targetLow != null && widget.targetHigh != null,
      ),
    ],
  );
}
