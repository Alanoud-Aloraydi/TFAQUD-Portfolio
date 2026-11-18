import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/condition_file_row.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One card for each of [ranges], the last with where the condition comes
/// from and a row to change it in the medical file of [circleId].
class MeasurementRangeCards extends StatelessWidget {
  const MeasurementRangeCards({
    super.key,
    required this.circleId,
    required this.ranges,
  });

  final String circleId;
  final List<NormalRange> ranges;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final NormalRange range in ranges) ...[
        if (range != ranges.first) const SizedBox(height: 16),
        NormalRangeCard(
          range: range,
          footer: range == ranges.last
              ? context.tr('measurements.range_from_file')
              : null,
          action: range == ranges.last
              ? ConditionFileRow(circleId: circleId)
              : null,
        ),
      ],
    ],
  );
}
