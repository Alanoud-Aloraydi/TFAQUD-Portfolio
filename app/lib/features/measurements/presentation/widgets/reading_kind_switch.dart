import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The switch of the reading sheet between blood pressure and glucose; off
/// (null [onChanged]) when the reading answers a task of one kind.
class ReadingKindSwitch extends StatelessWidget {
  const ReadingKindSwitch({
    super.key,
    required this.kind,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final ValueChanged<MeasurementKind>? onChanged;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<MeasurementKind>(
    segments: {
      MeasurementKind.bp: context.tr('measurements.bp'),
      MeasurementKind.glucose: context.tr('measurements.glucose'),
    },
    selected: kind,
    onChanged: onChanged,
  );
}
