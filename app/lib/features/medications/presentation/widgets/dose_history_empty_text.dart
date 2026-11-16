import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Why a medicine's dose history is empty: the treatment has not started
/// yet, or no dose was due in the days that were read.
String doseHistoryEmptyText(BuildContext context, DateTime earliest) =>
    earliest.isAfter(PatientClockScope.of(context).today())
    ? context.tr(
        'medications.dose_history_not_started',
        args: <String>[formatMedicationDate(context, earliest)],
      )
    : context.tr('medications.no_dose_history');
