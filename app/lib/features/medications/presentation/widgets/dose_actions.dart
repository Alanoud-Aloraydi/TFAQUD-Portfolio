import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:flutter/material.dart';

/// Asks when the dose of [scheduledOn] was taken and returns that moment.
/// The time picked is the patient's wall clock on that day, wherever this
/// phone is; the wheel starts at now on that clock.
///
/// [circleId] picks the words: «متى أخذت الجرعة؟» for the patient, «متى تم
/// أخذ الجرعة؟» for someone caring for them ([CareVoice]).
Future<DateTime?> selectTakenTime(
  BuildContext context,
  DateTime scheduledOn, {
  String? circleId,
}) async {
  final PatientClock clock = PatientClockScope.of(context);
  final selected = await showTafaqodTimeSheet(
    context,
    initialTime: TimeOfDay.fromDateTime(clock.now()),
    title: CareVoice.tr(context, circleId, 'medications.actual_time'),
  );
  if (selected == null) return null;
  return clock.momentOf(scheduledOn, '${selected.hour}:${selected.minute}');
}
