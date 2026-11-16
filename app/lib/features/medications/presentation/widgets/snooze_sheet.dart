import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/medications/presentation/widgets/snooze_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «متى نذكّرك؟»: the person slides a ruler, 5 minutes a mark, up to
/// [limit] (12 hours, or less before the medicine's next dose), the same
/// ruler as «نذكّرك كل». Above it, how long («بعد ساعة و30 دقيقة») and the
/// time it means on the patient's [clock]. Returns the minutes chosen, or
/// null when the sheet is closed.
Future<int?> showSnoozeSheet(
  BuildContext context, {
  required Duration limit,
  required PatientClock clock,
}) => showGlassSheet<int>(
  context,
  title: context.tr('reminders.snooze_title'),
  builder: (_) => SnoozeBody(maxMinutes: limit.inMinutes, clock: clock),
);
