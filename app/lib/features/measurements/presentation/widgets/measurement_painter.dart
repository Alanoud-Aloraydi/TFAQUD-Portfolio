import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/remind_later_check.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/chart_target.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/chart_axis.dart';
import 'package:app/features/measurements/presentation/widgets/chart_readings.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/registered_dose_reminders.dart';
import 'package:app/features/medications/presentation/widgets/snooze_sheet.dart';
import 'package:app/features/medications/presentation/widgets/snooze_task_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Draws a month of readings: glucose as a line of dots, blood pressure as
/// a capsule from the lower number to the upper one, over the normal bands.
/// The axis holds the range the readings live in, never down to zero.
class MeasurementPainter extends CustomPainter {
  MeasurementPainter(
    this.kind,
    this.readings,
    this.month,
    this.target,
    this.clock, {
    this.view = ChartZoom.none,
  });

  final MeasurementKind kind;
  final List<MeasurementReading> readings;
  final CalendarMonth month;
  final ChartTarget target;

  /// The patient's clock: a reading falls on its day where they live.
  final PatientClock clock;

  /// How far the days are spread by a pinch or «+», and scrolled.
  final ChartZoom view;

  @override
  void paint(Canvas canvas, Size size) {
    final ChartScale scale = ChartScale.of(
      size,
      month,
      readings,
      target.high,
      targetLow: target.low,
      kind: kind,
      view: view,
    );
    paintChartBands(canvas, scale, target);
    paintValueAxis(canvas, scale);
    final Map<int, List<MeasurementReading>> byDay = readingsByDay(
      readings,
      month,
      clock,
    );
    paintChartReadings(canvas, scale, size, kind, byDay);
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) =>
      oldDelegate.readings != readings ||
      oldDelegate.month != month ||
      oldDelegate.target != target ||
      oldDelegate.clock != clock ||
      oldDelegate.view != view;
}

/// The normal bands, the outer first so an inner one shows over it.
void paintChartBands(Canvas canvas, ChartScale scale, ChartTarget target) {
  for (final ChartBand band in target.bands) {
    canvas.drawRect(
      Rect.fromLTRB(
        ChartScale.chartLeft,
        scale.y(band.high),
        scale.right,
        scale.y(band.low),
      ),
      Paint()..color = ChartColors.band(band),
    );
  }
}

/// «ذكّرني لاحقًا» for a measurement: the same ruler, the same words and
/// the same look a dose has, so every task on «اليوم» answers the same
/// way — the reading had only «تسجيل قراءة» and «تخطي» before, and a
/// person who could not measure right now had nowhere to put it.
class MeasurementSnoozeButton extends StatefulWidget {
  const MeasurementSnoozeButton({
    super.key,
    required this.task,
    required this.circleId,
  });

  final MeasurementOccurrence task;
  final String circleId;

  @override
  State<MeasurementSnoozeButton> createState() =>
      MeasurementSnoozeButtonState();
}

/// Shows how the measurement stands with its reminder, and puts it off.
class MeasurementSnoozeButtonState extends State<MeasurementSnoozeButton> {
  Future<void> _snooze() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!await mayRemindLater(context) || !mounted) return;
    final PatientClock clock = PatientClockScope.of(context);
    final Duration limit = measurementSnoozeLimitOf(context, widget.task);
    if (limit.inMinutes < snoozeStepMinutes) {
      AppToast.showText(messenger, context.tr('reminders.snooze_none'));
      return;
    }
    final int? minutes = await showSnoozeSheet(
      context,
      limit: limit,
      clock: clock,
    );
    if (!mounted) return;
    final DoseReminders? reminders = registeredDoseReminders();
    if (minutes == null || reminders == null) return;
    final bool done = await reminders.snoozeMeasurement(
      widget.circleId,
      widget.task,
      Duration(minutes: minutes),
    );
    if (!mounted) return;
    sayRemindLater(
      messenger,
      context,
      done: done,
      snoozed: context.tr(
        'reminders.snoozed',
        args: <String>[afterDuration(context, minutes)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DoseReminders? reminders = registeredDoseReminders();
    final SharedSnooze? shared = widget.task.snooze;
    if (reminders == null) {
      return SnoozeTaskButton(at: null, shared: shared, onPressed: _snooze);
    }
    final String key = measurementSnoozeKey(widget.circleId, widget.task);
    return ValueListenableBuilder<Map<String, TaskSnooze>>(
      valueListenable: reminders.snoozes,
      builder: (BuildContext context, Map<String, TaskSnooze> snoozed, _) =>
          SnoozeTaskButton(
            at: snoozed[key]?.at,
            shared: shared,
            onPressed: _snooze,
          ),
    );
  }
}

/// How long the measurement may still be put off: 12 hours, and never
/// past halfway to the reading that follows it, which the occurrence
/// carries as [MeasurementOccurrence.nextAt].
Duration measurementSnoozeLimitOf(
  BuildContext context,
  MeasurementOccurrence task,
) {
  final PatientClock clock = PatientClockScope.of(context);
  return snoozeLimit(
    now: DateTime.now().toUtc(),
    dose: clock.momentOf(task.scheduledOn, task.time),
    nextDose: task.nextAt,
  );
}
