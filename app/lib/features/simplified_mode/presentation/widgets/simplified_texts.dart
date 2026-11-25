import 'package:app/app/services/reminders/dose_reminders.dart'
    show SharedSnooze, TaskSnooze;
import 'package:app/core/localization/appointment_texts.dart';
import 'package:app/core/localization/greeting.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/simplified_mode/domain/entities/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_contact_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

export 'package:app/features/simplified_mode/presentation/widgets/simplified_contact_lines.dart';

/// آ«ط¨ط¹ط¯ ط§ظ„ظ…ط؛ط±ط¨آ».
String simplifiedPeriod(BuildContext context, PrayerPeriod period) =>
    context.tr('simplified_mode.period.${period.name}');

/// The plain part of the day beside a period: آ«ط§ظ„ظ…ط³ط§ط،آ».
String simplifiedPeriodHint(BuildContext context, PrayerPeriod period) =>
    context.tr('simplified_mode.period_hint.${period.name}');

/// The app's one greeting, the detailed mode's too: آ«طµط¨ط§ط­ ط§ظ„ط®ظٹط±طŒ ظ…ط±ظٹظ…آ»
/// from Fajr until Dhuhr, آ«ظ…ط³ط§ط، ط§ظ„ط®ظٹط±طŒ ظ…ط±ظٹظ…آ» after ([prayers] is today's;
/// without it, the fallback times of [isMorning]).
String simplifiedGreeting(
  BuildContext context,
  String? name,
  DateTime now,
  PrayerDay? prayers,
) => greeting(
  context,
  PatientClockScope.of(context).wallTime(now),
  name,
  fajr: prayers?.times[Prayer.fajr],
  dhuhr: prayers?.times[Prayer.dhuhr],
);

/// آ«ط³ط£ط°ظƒظ‘ط±ظƒ 2:09 ظ…ط³ط§ط،ظ‹آ» on [task] of [circleId] while this phone put it
/// off ([snoozes]); آ«ط§ظ„طھط°ظƒظٹط± ظ…ط¤ط¬ظ‘ظ„ ط¥ظ„ظ‰ 2:09 ظ…ط³ط§ط،ظ‹طŒ ظ„ظٹظ†آ» while someone else
/// in the circle did; null for any other task, or once its reminder came.
String? simplifiedSnoozed(
  BuildContext context,
  Map<String, TaskSnooze> snoozes,
  String circleId,
  TodayTask task,
) {
  if (task.status == TodayTaskStatus.done) return null;
  final TaskSnooze? snooze = snoozes[task.snoozeKey(circleId)];
  if (snooze != null) {
    return context.tr(
      'simplified_mode.snoozed_until',
      args: <String>[simplifiedClockAt(context, snooze.at)],
    );
  }
  final SharedSnooze? shared = task.dose?.snooze ?? task.measurement?.snooze;
  if (shared == null || !shared.waitsAt(DateTime.now())) return null;
  final String at = simplifiedClockAt(context, shared.remindAt);
  final String? name = shared.byName;
  return name == null
      ? context.tr('simplified_mode.snoozed_shared', args: <String>[at])
      : context.tr('simplified_mode.snoozed_by', args: <String>[at, name]);
}

/// What to take: آ«ط­ط¨ط© ظˆط§ط­ط¯ط©آ», or آ«2 ط­ط¨ط©آ».
String simplifiedDoseAmount(BuildContext context, DoseOccurrence dose) {
  if (dose.doseValue == 1) {
    return context.tr('simplified_mode.dose_one.${dose.doseUnit.name}');
  }
  return formatMedicationDose(context, dose.doseValue, dose.doseUnit);
}

/// The medicine's strength: آ«500 ظ…ظ„ط؛آ».
String simplifiedStrength(BuildContext context, DoseOccurrence dose) =>
    '${formatMedicationNumber(dose.strengthValue)} '
    '${context.tr('medications.strength_display.${dose.strengthUnit.name}')}';

/// آ«ظ‚ظٹط§ط³ ط§ظ„ط¶ط؛ط·آ» or آ«ظ‚ظٹط§ط³ ط§ظ„ط³ظƒط±آ».
String simplifiedMeasurementTitle(BuildContext context, MeasurementKind kind) =>
    context.tr('simplified_mode.measure_${kind.name}');

/// A task's name on a row or a card.
String simplifiedTaskTitle(BuildContext context, TodayTask task) =>
    switch (task.kind) {
      TodayTaskKind.medication => task.dose!.name,
      TodayTaskKind.measurement => simplifiedMeasurementTitle(
        context,
        task.measurement!.kind,
      ),
      TodayTaskKind.appointment => appointmentTitle(context, task.appointment!),
    };
