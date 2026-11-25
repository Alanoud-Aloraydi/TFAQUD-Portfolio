import 'package:app/core/localization/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// One dose of a schedule or an occurrence, «1 قرص».
String formatMedicationDose(
  BuildContext context,
  double value,
  DoseUnit unit,
) => context.tr(
  'medications.dose',
  args: [
    formatMedicationNumber(value),
    context.tr('medications.unit.${unit.name}'),
  ],
);
