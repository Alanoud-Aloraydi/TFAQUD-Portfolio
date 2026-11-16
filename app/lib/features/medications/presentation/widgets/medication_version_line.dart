import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What a medicine was in one version, «ميتفورمين، 500 ملغ، أقراص».
String medicationVersionLine(BuildContext context, MedicationVersion version) =>
    '${version.name}، '
    '${formatMedicationNumber(version.strengthValue)} '
    '${context.tr('medications.strength_display.${version.strengthUnit.name}')}، '
    '${context.tr('medications.form.${version.dosageForm.name}')}';
