part of 'measurement_chart.dart';

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

  void _select(Offset at, double width) {
    final MeasurementReading? reading = chartReadingTapped(
      at,
      chart: widget,
      size: Size(width, _height),
      view: _view,
      clock: PatientClockScope.of(context),
    );
    setState(() => _selected = reading);
  }

  /// «+» or «−»: [times] as wide, around the middle of the plot.
  void _zoom(double width, double times) {
    final ChartZoom next = _view.zoomedBy(times, ChartScale.plotWidth(width));
    setState(() => _view = next);
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
          child: MeasurementChartCanvas(
            chart: widget,
            view: _view,
            height: _height,
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
