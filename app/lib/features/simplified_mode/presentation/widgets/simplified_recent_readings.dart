import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reading_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «آخر القياسات»: the last few readings of this kind, newest first, each
/// with how it was judged. A patient who measures every day has nowhere
/// else in this mode to see what the last one was.
class SimplifiedRecentReadings extends StatelessWidget {
  const SimplifiedRecentReadings({
    super.key,
    required this.readings,
    required this.kind,
    required this.now,
    this.most = 3,
  });

  final List<MeasurementReading> readings;
  final MeasurementKind kind;
  final DateTime now;

  /// How many are shown: a short list to glance at, not a record.
  final int most;

  @override
  Widget build(BuildContext context) {
    final List<MeasurementReading> shown = <MeasurementReading>[
      for (final MeasurementReading reading in readings)
        if (reading.kind == kind) reading,
    ].take(most).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.tr('simplified_mode.recent_readings'),
          style: SimplifiedStyle.head(SimplifiedStyle.title),
        ),
        const SizedBox(height: 12),
        SimplifiedCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SimplifiedStyle.pad,
            vertical: 4,
          ),
          child: Column(
            children: <Widget>[
              for (final MeasurementReading reading in shown)
                SimplifiedReadingRow(reading: reading, kind: kind, now: now),
            ],
          ),
        ),
      ],
    );
  }
}
