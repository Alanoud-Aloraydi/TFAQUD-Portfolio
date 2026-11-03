import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shared category selector for home composition tabs.
class HomeCategoryControl extends StatelessWidget {
  const HomeCategoryControl({
    super.key,
    required this.medicationCount,
    this.measurementCount = 0,
    this.appointmentCount = 0,
    this.showCounts = true,
    this.selected = 'medications',
    this.onChanged,
  });

  final int medicationCount;
  final int measurementCount;
  final int appointmentCount;
  final bool showCounts;
  final String selected;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<String>(
    segments: <String, String>{
      'medications': context.tr('home_category.medications'),
      'measurements': context.tr('home_category.measurements'),
      'appointments': context.tr('home_category.appointments'),
    },
    selected: selected,
    enabledValues: const <String>{
      'medications',
      'measurements',
      'appointments',
    },
    onChanged: onChanged,
    counts: showCounts
        ? <String, int>{
            'medications': medicationCount,
            'measurements': measurementCount,
            'appointments': appointmentCount,
          }
        : null,
  );
}
