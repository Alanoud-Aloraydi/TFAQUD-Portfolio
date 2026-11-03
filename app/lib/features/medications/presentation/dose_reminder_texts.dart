import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';

/// The Arabic words of the dose reminders, read when they are set (the
/// translations are loaded by then).
final DoseReminderTexts doseReminderTexts = DoseReminderTexts(
  // «حان موعد دواء أمي نورة».
  title: (ReminderCircle circle) =>
      'reminders.dose_title'.tr(args: <String>[circle.name]),
  // Only the medicine's name, «ميتفورمين»: the dose is on the Today page.
  body: (DoseOccurrence dose) => dose.name,
  keepTitle: () => 'reminders.keep_title'.tr(),
  keepBody: () => 'reminders.keep_body'.tr(),
);
