import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The top of the reading sheet: the kind switch, the numbers, and under
/// them «المعدل الطبيعي» with the [level] of the typed value marked.
class ReadingValuesSection extends StatelessWidget {
  const ReadingValuesSection({
    super.key,
    required this.kind,
    required this.onKindChanged,
    required this.systolic,
    required this.diastolic,
    required this.glucose,
    required this.onChanged,
    this.outOfRange,
    this.range,
    this.level,
  });

  final MeasurementKind kind;
  final ValueChanged<MeasurementKind>? onKindChanged;
  final TextEditingController systolic;
  final TextEditingController diastolic;
  final TextEditingController glucose;

  /// A typed digit: the level follows it, and an old error goes.
  final VoidCallback onChanged;

  /// The message key of numbers out of range, said under the last one.
  final String? outOfRange;
  final NormalRange? range;
  final MeasurementLevel? level;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadingKindSwitch(kind: kind, onChanged: onKindChanged),
      const SizedBox(height: AppSpacing.lg),
      ReadingValueFields(
        kind: kind,
        systolic: systolic,
        diastolic: diastolic,
        glucose: glucose,
        onChanged: onChanged,
        outOfRange: outOfRange,
      ),
      // Never in the way: saving does not wait for it, the server
      // judges the reading either way.
      if (range != null) ...[
        const SizedBox(height: AppSpacing.lg),
        ReadingRangeCard(range: range!, level: level),
      ],
    ],
  );
}

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
