import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
