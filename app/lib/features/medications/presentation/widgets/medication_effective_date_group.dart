import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_effective_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A revision starts right away or on a later selected day.
class MedicationEffectiveDateGroup extends StatelessWidget {
  const MedicationEffectiveDateGroup({
    super.key,
    required this.data,
    required this.onChanged,
    this.circleId,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  /// For the words: the patient's «جدولك» or the patient's name.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final today = PatientClockScope.of(context).today();
    final selected = data.effectiveFromOn ?? today;
    final isNow = DateUtils.isSameDay(selected, today);
    return InsetGroup(
      header: context.tr('medications.effective_question'),
      footer: CareVoice.tr(context, circleId, 'medications.effective_hint'),
      children: <Widget>[
        MedicationEffectiveChips(
          data: data,
          onChanged: onChanged,
          today: today,
          selected: selected,
          isNow: isNow,
        ),
        if (!isNow)
          MedicationDateRow(
            label: context.tr('medications.effective_from'),
            value: selected,
            firstDate: today,
            onChanged: (DateTime? date) {
              if (date == null) return;
              data.effectiveFromOn = date;
              onChanged();
            },
          ),
      ],
    );
  }
}
