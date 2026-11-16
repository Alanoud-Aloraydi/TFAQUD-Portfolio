import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The facts of a medicine, in the order the page reads them: its form, why
/// it is taken, how, when a dose counts as missed, the treatment period,
/// and, for a plan that has not started, the day it takes over.
List<Widget> medicationFactRows(BuildContext context, MedicationPlan plan) {
  final MedicationVersion version = plan.version;
  final DateTime today = PatientClockScope.of(context).today();
  Widget row(String label, String value) =>
      InfoRow(label: context.tr(label), value: value);
  return <Widget>[
    row(
      'medications.dosage_form',
      context.tr('medications.form.${version.dosageForm.name}'),
    ),
    if (version.reason case final value?) row('medications.reason', value),
    if (version.instructions case final value?)
      row('medications.instructions', value),
    row(
      'medications.missed_after',
      arabicCount(context, ArabicCount.minutes, version.missedAfterMinutes),
    ),
    row(
      'medications.treatment_period',
      formatMedicationPeriod(
        context,
        version.startsOn,
        version.endsOn,
        today: today,
      ),
    ),
    if (plan.isScheduledOn(today))
      row(
        'medications.effective_from',
        formatMedicationDate(context, version.effectiveFromOn),
      ),
  ];
}
