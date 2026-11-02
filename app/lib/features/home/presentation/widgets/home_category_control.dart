import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shared home category selector while only medication data is available.
class HomeCategoryControl extends StatelessWidget {
  const HomeCategoryControl({super.key, required this.medicationCount});

  final int medicationCount;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<String>(
    segments: <String, String>{
      'medications': context.tr('home_category.medications'),
      'measurements': context.tr('home_category.measurements'),
      'appointments': context.tr('home_category.appointments'),
    },
    selected: 'medications',
    enabledValues: const <String>{'medications'},
    counts: <String, int>{'medications': medicationCount},
  );
}
