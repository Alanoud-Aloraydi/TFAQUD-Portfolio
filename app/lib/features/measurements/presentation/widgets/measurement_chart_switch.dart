import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The switch of a chart card between the chart and the calendar.
class MeasurementChartSwitch extends StatelessWidget {
  const MeasurementChartSwitch({
    super.key,
    required this.calendar,
    required this.onChanged,
  });

  final bool calendar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<bool>(
    segments: <bool, String>{
      false: context.tr('measurements.chart'),
      true: context.tr('measurements.calendar'),
    },
    selected: calendar,
    onChanged: onChanged,
  );
}
