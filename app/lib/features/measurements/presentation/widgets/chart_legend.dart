import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axis.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_painter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the colours of a month chart mean, in the colours it draws with
/// ([ChartColors]): a reading, one outside its range, and each band.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.target});

  final ChartTarget target;

  @override
  Widget build(BuildContext context) {
    // Blood pressure's two zones share one name.
    final Map<String, ChartBand> bands = <String, ChartBand>{
      for (final ChartBand band in target.bands) band.labelKey: band,
    };
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        ChartKey(
          ChartColors.reading,
          context.tr('measurements.chart_legend_reading'),
        ),
        ChartKey(
          ChartColors.outside,
          context.tr('measurements.chart_legend_outside'),
        ),
        for (final MapEntry<String, ChartBand> entry in bands.entries)
          ChartKey(ChartColors.band(entry.value), context.tr(entry.key)),
      ],
    );
  }
}

class ChartKey extends StatelessWidget {
  const ChartKey(this.color, this.label, {super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          // A pale band still shows its edge.
          border: Border.all(color: AppSemanticColors.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: const SizedBox(width: 12, height: 8),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// The drawing of a [chart], [height] high, spread and scrolled by [view].
class MeasurementChartCanvas extends StatelessWidget {
  const MeasurementChartCanvas({
    super.key,
    required this.chart,
    required this.view,
    required this.height,
  });

  final MeasurementChart chart;
  final ChartZoom view;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: MeasurementPainter(
          chart.kind,
          chart.readings,
          chart.month,
          chart.target,
          PatientClockScope.of(context),
          view: view,
        ),
      ),
    );
  }
}

/// The touches of a month chart [width] wide: a tap ([onTap], where), and a
/// pinch or a drag ([onView], the new view). What was under the fingers
/// when they went down stays under them. A drag up or down still scrolls
/// the page: it claims the touch first.
class ChartGestures extends StatefulWidget {
  const ChartGestures({
    super.key,
    required this.view,
    required this.width,
    required this.onView,
    required this.onTap,
    required this.child,
  });

  final ChartZoom view;
  final double width;
  final ValueChanged<ChartZoom> onView;
  final ValueChanged<Offset> onTap;
  final Widget child;

  @override
  State<ChartGestures> createState() => _ChartGesturesState();
}

class _ChartGesturesState extends State<ChartGestures> {
  /// The view, and the focal point left of the right edge, at the start.
  ChartZoom _start = ChartZoom.none;
  double _from = 0;

  double _fromRight(Offset at) => widget.width - ChartScale.labelWidth - at.dx;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: (details) => widget.onTap(details.localPosition),
    onScaleStart: (details) {
      _start = widget.view;
      _from = _fromRight(details.localFocalPoint);
    },
    onScaleUpdate: (details) => widget.onView(
      _start.moved(
        from: _from,
        at: _fromRight(details.localFocalPoint),
        to: _start.zoom * details.scale,
        width: ChartScale.plotWidth(widget.width),
      ),
    ),
    child: widget.child,
  );
}

/// «−» and «+» beside the chart's legend: the same zoom as a pinch, for
/// one finger or a screen reader (WCAG 2.5.1). Each turns off at its end.
class ChartZoomButtons extends StatelessWidget {
  const ChartZoomButtons({super.key, required this.zoom, required this.onZoom});

  final double zoom;

  /// Called with how many times wider: [ChartZoom.step], or its inverse.
  final ValueChanged<double> onZoom;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      IconButton(
        tooltip: context.tr('measurements.zoom_out'),
        onPressed: zoom > 1 ? () => onZoom(1 / ChartZoom.step) : null,
        icon: const Icon(ActionIcons.minus),
      ),
      IconButton(
        tooltip: context.tr('measurements.zoom_in'),
        onPressed: zoom < ChartZoom.most ? () => onZoom(ChartZoom.step) : null,
        icon: const Icon(ActionIcons.plus),
      ),
    ],
  );
}

/// The reading a tap [at] selects on [chart], drawn [size] big and spread
/// by [view]; null when no reading is within reach.
MeasurementReading? chartReadingTapped(
  Offset at, {
  required MeasurementChart chart,
  required Size size,
  required ChartZoom view,
  required PatientClock clock,
}) {
  final ChartScale scale = ChartScale.of(
    size,
    chart.month,
    chart.readings,
    chart.target.high,
    targetLow: chart.target.low,
    kind: chart.kind,
    view: view,
  );
  final Map<int, List<MeasurementReading>> byDay = readingsByDay(
    chart.readings,
    chart.month,
    clock,
  );
  return chartReadingAt(scale, byDay, chart.kind, at);
}

/// The reading a tap at [at] means on a month chart drawn with [scale]: the
/// nearest dot or capsule within a finger's reach, among those in view;
/// null when none is that close. [byDay] is the month's readingsByDay.
MeasurementReading? chartReadingAt(
  ChartScale scale,
  Map<int, List<MeasurementReading>> byDay,
  MeasurementKind kind,
  Offset at,
) {
  const double reachX = 22;
  const double reachY = 18;
  MeasurementReading? nearest;
  double distance = double.infinity;
  for (final MapEntry<int, List<MeasurementReading>> entry in byDay.entries) {
    for (int index = 0; index < entry.value.length; index++) {
      final MeasurementReading reading = entry.value[index];
      final double x = scale.center(entry.key, index, entry.value.length);
      // Zoomed in, a reading scrolled out of view cannot be tapped.
      if (x < ChartScale.chartLeft || x > scale.right) continue;
      final double dx = (x - at.dx).abs();
      final double dy = _verticalMiss(scale, reading, kind, at.dy);
      if (dx + dy < distance && dx <= reachX && dy <= reachY) {
        nearest = reading;
        distance = dx + dy;
      }
    }
  }
  return nearest;
}

/// How far [dy] is above or below [reading]: a glucose reading is a dot, a
/// pressure reading the capsule between its two numbers.
double _verticalMiss(
  ChartScale scale,
  MeasurementReading reading,
  MeasurementKind kind,
  double dy,
) {
  final double first = scale.y(reading.valueOne!);
  final double second = kind == MeasurementKind.glucose
      ? first
      : scale.y(reading.valueTwo!);
  final double top = first < second ? first : second;
  final double bottom = first < second ? second : first;
  return dy < top ? top - dy : (dy > bottom ? dy - bottom : 0);
}
