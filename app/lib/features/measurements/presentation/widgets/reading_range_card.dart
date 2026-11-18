import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/condition_file_row.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
