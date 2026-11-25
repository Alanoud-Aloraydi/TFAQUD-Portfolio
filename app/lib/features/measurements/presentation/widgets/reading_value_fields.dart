import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/condition_file_row.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:app/features/measurements/presentation/widgets/reading_number_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
