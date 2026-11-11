import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «500 ملغ» for the medicine of [occurrence].
String doseStrengthText(BuildContext context, DoseOccurrence occurrence) =>
    '${formatMedicationNumber(occurrence.strengthValue)} '
    '${context.tr('medications.strength_display.${occurrence.strengthUnit.name}')}';
