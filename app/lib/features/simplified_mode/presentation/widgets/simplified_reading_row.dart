import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// «8:00 ص» for today, «الأحد 8:00 ص» for a day before it.
String simplifiedReadingWhen(
  BuildContext context,
  MeasurementReading reading,
  DateTime now,
) {
  final DateTime at = reading.measuredAt ?? reading.recordedAt;
  final String clock = wallTimeText(at);
  if (DateUtils.isSameDay(at, now)) return clock;
  return '${context.tr('common.weekdays.${at.weekday}')} $clock';
}

/// Opens the full-screen reminder of that exact [task], the same screen a
/// tapped notification opens, for a dose, a reading or a visit alike: its
/// picture, and its own answer («أخذته», «تسجيل القياس الآن», «حضرت»).
void openSimplifiedTask(BuildContext context, TodayTask task, String circleId) {
  unawaited(
    context.push(
      Routes.simplifiedReminder,
      extra: ReminderRequest.of(task, circleId),
    ),
  );
}
