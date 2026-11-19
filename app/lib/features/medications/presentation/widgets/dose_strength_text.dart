import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «500 ملغ» for the medicine of [occurrence].
String doseStrengthText(BuildContext context, DoseOccurrence occurrence) =>
    strengthText(context, occurrence.strengthValue, occurrence.strengthUnit);

/// «500 ملغ»: a medicine's [value] in its [unit].
String strengthText(BuildContext context, double value, StrengthUnit unit) =>
    '${formatMedicationNumber(value)} '
    '${context.tr('medications.strength_display.${unit.name}')}';
