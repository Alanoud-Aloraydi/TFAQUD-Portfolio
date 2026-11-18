import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
