import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/dose_reminder_texts.dart';
import 'package:app/app/services/reminders/snooze_putter.dart';
import 'package:app/app/services/reminders/snooze_settling.dart';
import 'package:app/core/reminders/task_snooze.dart';
import 'package:app/core/utils/time_zones.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// «ذكّرني لاحقًا» on a dose or a measurement: the words of its own
/// reminder, put off with the [putter].
class DoseSnoozer {
  DoseSnoozer({
    required this.putter,
    required this.texts,
    required this.circles,
    required this.now,
  });

  final SnoozePutter putter;
  final DoseReminderTexts texts;

  /// The circles synced now, for the words of their reminders.
  final List<ReminderCircle> Function() circles;
  final DateTime Function() now;

  /// «ذكّرني لاحقًا» on [dose] of [circleId], in either mode: its reminder
  /// again [after] from now, with the words of its own reminder. False
  /// while the reminders are off: nothing is put off.
  Future<bool> snoozeDose(
    String circleId,
    DoseOccurrence dose,
    Duration after,
  ) {
    final ReminderCircle circle = circleOf(circles(), circleId);
    return putter.put(
      key: doseSnoozeKey(circleId, dose),
      after: after,
      snooze: TaskSnooze(
        circleId: circleId,
        task: SnoozedTask.dose,
        subject: dose.name,
        at: now().toUtc().add(after),
      ),
      title: texts.title(circle, dose),
      body: texts.body(circle, dose),
    );
  }

  /// The same for a measurement [task].
  Future<bool> snoozeMeasurement(
    String circleId,
    MeasurementOccurrence task,
    Duration after,
  ) {
    final ReminderCircle circle = circleOf(circles(), circleId);
    return putter.put(
      key: measurementSnoozeKey(circleId, task),
      after: after,
      snooze: TaskSnooze(
        circleId: circleId,
        task: SnoozedTask.measurement,
        subject: task.kind.name,
        at: now().toUtc().add(after),
      ),
      title: texts.measurementTitle(circle),
      body: texts.measurementBody(circle, task),
    );
  }

  /// «ذكّرني لاحقًا» from a notification; see [snoozeFromTap].
  Future<bool> snoozeTap(String tap) => snoozeFromTap(putter, now, tap);
}

/// The synced circle of [circleId] among [circles], for the words of its
/// reminders.
ReminderCircle circleOf(List<ReminderCircle> circles, String circleId) =>
    circles.where((ReminderCircle item) => item.id == circleId).firstOrNull ??
    ReminderCircle(
      id: circleId,
      name: '',
      viewerId: null,
      viewerIsPatient: false,
      timeZone: defaultPatientZone,
    );
