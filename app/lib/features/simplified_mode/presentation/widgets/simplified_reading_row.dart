import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reading_when.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// One past reading: what it was, how it was judged, and when.
class SimplifiedReadingRow extends StatelessWidget {
  const SimplifiedReadingRow({
    super.key,
    required this.reading,
    required this.kind,
    required this.now,
    this.divided = true,
  });

  final MeasurementReading reading;
  final MeasurementKind kind;
  final DateTime now;

  /// A rule above this row, parting it from the one before. The first row
  /// has none: the card's own edge is already a line there.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final MeasurementLevel? level = reading.level;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: divided
            ? const BoxDecoration(
                border: Border(top: BorderSide(color: SimplifiedColors.chip)),
              )
            : null,
        child: Row(
          children: <Widget>[
            Text(
              reading.valueTwo == null
                  ? '${reading.valueOne}'
                  : '${reading.valueOne}/${reading.valueTwo}',
              style: SimplifiedStyle.head(SimplifiedStyle.headline),
            ),
            const SizedBox(width: 12),
            if (level != null) ...<Widget>[
              ExcludeSemantics(child: Icon(level.icon, size: 20)),
              const SizedBox(width: 6),
              Text(
                level.label(context, kind),
                style: SimplifiedStyle.text(SimplifiedStyle.caption),
              ),
            ],
            const Spacer(),
            Text(
              simplifiedReadingWhen(context, reading, now),
              style: SimplifiedStyle.text(
                SimplifiedStyle.caption,
                color: SimplifiedColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
