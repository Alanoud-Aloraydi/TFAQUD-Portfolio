import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';

/// The Arabic words of the dose reminders, read when they are set (the
/// translations are loaded by then).
final DoseReminderTexts doseReminderTexts = DoseReminderTexts(
  // «حان موعد دواء أمي نورة».
  title: (ReminderCircle circle) =>
      'reminders.dose_title'.tr(args: <String>[circle.name]),
  // «ميتفورمين 500 mg · 1 قرص · بعد الأكل».
  body: (DoseOccurrence dose) => <String>[
    '${dose.name} ${formatMedicationNumber(dose.strengthValue)} '
        '${dose.strengthUnit.apiValue}',
    'medications.dose'.tr(
      args: <String>[
        formatMedicationNumber(dose.doseValue),
        'medications.unit.${dose.doseUnit.name}'.tr(),
      ],
    ),
    if (dose.instructions?.trim() case final String note when note.isNotEmpty)
      note,
  ].join(' · '),
  keepTitle: () => 'reminders.keep_title'.tr(),
  keepBody: () => 'reminders.keep_body'.tr(),
);
