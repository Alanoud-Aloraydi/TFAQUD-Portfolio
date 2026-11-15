import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/chart_target.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/chart_gestures.dart';
import 'package:app/features/measurements/presentation/widgets/chart_hit.dart';
import 'package:app/features/measurements/presentation/widgets/chart_legend.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom_buttons.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_painter.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:flutter/material.dart';

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
  final DateTime month;
  final String circleId;

  /// The normal bands drawn behind the readings.
  final ChartTarget target;

  @override
  State<MeasurementChart> createState() => _MeasurementChartState();
}

class _MeasurementChartState extends State<MeasurementChart> {
  static const double _height = 176;

  MeasurementReading? _selected;
  ChartZoom _view = ChartZoom.none;

  @override
  void didUpdateWidget(MeasurementChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) _view = ChartZoom.none;
    if (_selected != null &&
        !widget.readings.any((item) => item.id == _selected!.id)) {
      _selected = null;
    }
  }

  /// «+» or «−»: [times] as wide, around the middle of the plot.
  void _zoom(double width, double times) {
    final double plot = ChartScale.plotWidth(width);
    final ChartZoom next = _view.moved(
      from: plot / 2,
      at: plot / 2,
      to: _view.zoom * times,
      width: plot,
    );
    setState(() => _view = next);
  }

  void _select(Offset at, double width) {
    final ChartScale scale = ChartScale.of(
      Size(width, _height),
      widget.month,
      widget.readings,
      widget.target.high,
      targetLow: widget.target.low,
      kind: widget.kind,
      view: _view,
    );
    final Map<int, List<MeasurementReading>> byDay = readingsByDay(
      widget.readings,
      widget.month,
      PatientClockScope.of(context),
    );
    setState(() => _selected = chartReadingAt(scale, byDay, widget.kind, at));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChartGestures(
          view: _view,
          width: constraints.maxWidth,
          onView: (view) => setState(() => _view = view),
          onTap: (at) => _select(at, constraints.maxWidth),
          child: SizedBox(
            height: _height,
            child: CustomPaint(
              painter: MeasurementPainter(
                widget.kind,
                widget.readings,
                widget.month,
                widget.target,
                PatientClockScope.of(context),
                view: _view,
              ),
            ),
          ),
        ),
        if (_selected case final reading?) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          MeasurementReadingTile(reading: reading, circleId: widget.circleId),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(child: ChartLegend(target: widget.target)),
            ChartZoomButtons(
              zoom: _view.zoom,
              onZoom: (times) => _zoom(constraints.maxWidth, times),
            ),
          ],
        ),
      ],
    ),
  );
}
