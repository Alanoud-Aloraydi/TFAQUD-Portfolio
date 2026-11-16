import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_icon.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_icon_hero.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The reminder of a reading: its kind's picture, how to take it, and
/// «تسجيل القياس الآن» or «ذكّرني لاحقًا». Null when [task] no longer
/// waits.
SimplifiedReminderContent? reminderMeasurementContent(
  BuildContext context,
  TodayTask? task,
  SimplifiedDay day,
) {
  if (task == null) return null;
  final MeasurementOccurrence item = task.measurement!;
  final bool bp = item.kind == MeasurementKind.bp;
  return SimplifiedReminderContent(
    lead: context.tr('simplified_mode.time_for'),
    name: simplifiedMeasurementTitle(context, item.kind),
    line: bp
        ? context.tr('simplified_mode.bp_rest')
        : simplifiedTime(context, item.time),
    chips: <String>[
      if (bp) context.tr('simplified_mode.bp_arm'),
      if (item.measurementState case final state?)
        context.tr('measurements.condition.$state'),
    ],
    hero: (double height) => SimplifiedReminderIconHero(
      icon: measurementIcon(item.kind),
      ground: CareVisuals.measurementTile,
      height: height,
    ),
    yesLabel: context.tr('simplified_mode.measure_now'),
    onYes: () => context.pushReplacement(
      Routes.simplifiedMeasure(day.circleId),
      extra: item,
    ),
    onLater: () =>
        context.pushReplacement(Routes.simplifiedSnooze, extra: task),
  );
}
