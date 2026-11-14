import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One past reading: what it was, how it was judged, and when.
class SimplifiedReadingRow extends StatelessWidget {
  const SimplifiedReadingRow({
    super.key,
    required this.reading,
    required this.kind,
    required this.now,
  });

  final MeasurementReading reading;
  final MeasurementKind kind;
  final DateTime now;

  /// «8:00 ص» for today, «الأحد 8:00 ص» for a day before it.
  String _when(BuildContext context) {
    final DateTime at = reading.measuredAt ?? reading.recordedAt;
    final String clock = wallTimeText(at);
    if (DateUtils.isSameDay(at, now)) return clock;
    return '${context.tr('common.weekdays.${at.weekday}')} $clock';
  }

  @override
  Widget build(BuildContext context) {
    final MeasurementLevel? level = reading.level;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: SimplifiedStyle.chip)),
        ),
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
              _when(context),
              style: SimplifiedStyle.text(
                SimplifiedStyle.caption,
                color: SimplifiedStyle.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
