import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/reading_follow_up_button.dart';
import 'package:app/features/measurements/presentation/widgets/reading_status_pill.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:app/features/measurements/presentation/widgets/reading_value.dart';
import 'package:flutter/material.dart';

/// A reading outside its normal range in the attention box: its value,
/// level and range, and «تابعتها».
class OutsideReadingCard extends StatelessWidget {
  const OutsideReadingCard({super.key, required this.reading});

  final MeasurementReading reading;

  @override
  Widget build(BuildContext context) {
    return MeasurementAttentionCard(
      kind: reading.kind,
      title: ReadingTitles(reading: reading),
      status: ReadingValue(reading: reading),
      lines: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ReadingStatusPill(reading: reading),
        ),
        if (reading.range != null)
          Text(
            readingRangeText(context, reading),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
      actions: <Widget>[ReadingFollowUpButton(reading: reading)],
    );
  }
}
