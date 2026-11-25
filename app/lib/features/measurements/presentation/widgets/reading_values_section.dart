import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/condition_file_row.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:app/features/measurements/presentation/widgets/reading_number_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// The numbers of a reading, each with its unit, in one card: the upper and
/// lower number of a blood pressure, one under the other, or the one number
/// of a glucose.
class ReadingValueFields extends StatelessWidget {
  const ReadingValueFields({
    super.key,
    required this.kind,
    required this.systolic,
    required this.diastolic,
    required this.glucose,
    required this.onChanged,
    this.outOfRange,
  });

  final MeasurementKind kind;
  final TextEditingController systolic;
  final TextEditingController diastolic;
  final TextEditingController glucose;
  final VoidCallback onChanged;

  /// The message key of numbers out of range, said under the last one.
  final String? outOfRange;

  @override
  Widget build(BuildContext context) {
    final bool bp = kind == MeasurementKind.bp;
    final String unit = context.tr(
      bp ? 'measurements.bp_unit' : 'measurements.glucose_unit',
    );
    final String? error = outOfRange == null ? null : context.tr(outOfRange!);
    // The upper number on top, the lower under it; a number out of range is
    // said under the last one.
    return InsetGroup(
      children: [
        ReadingNumberField(
          label: context.tr(
            bp ? 'measurements.systolic' : 'measurements.value',
          ),
          unit: unit,
          controller: bp ? systolic : glucose,
          onChanged: onChanged,
          last: !bp,
          errorText: bp ? null : error,
        ),
        if (bp)
          ReadingNumberField(
            label: context.tr('measurements.diastolic'),
            unit: unit,
            controller: diastolic,
            onChanged: onChanged,
            errorText: error,
          ),
      ],
    );
  }
}

/// «المعدل الطبيعي» under the values of the reading sheet, with the [level]
/// the typed value falls in marked.
class ReadingRangeCard extends StatelessWidget {
  const ReadingRangeCard({super.key, required this.range, this.level});

  final NormalRange range;
  final MeasurementLevel? level;

  @override
  Widget build(BuildContext context) => NormalRangeCard(
    range: range,
    level: level,
    footer: context.tr('measurements.range_from_file'),
    // The condition is the medical file's, as on the plan's
    // form: changed there, and the range follows.
    action: ConditionFileRow(
      circleId: context.read<MeasurementReadingsCubit>().circleId!,
    ),
  );
}
