import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
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
        InsetBlock(
          semanticLabel: context.tr('medications.effective_question'),
          child: OptionChips(
            options: <ChipOption>[
              ChipOption('now', context.tr('medications.now')),
              ChipOption('date', context.tr('medications.specific_date')),
            ],
            isSelected: (String code) => code == 'now' ? isNow : !isNow,
            onTap: (String code) {
              if (code == 'now') {
                data.effectiveFromOn = today;
                onChanged();
              } else {
                _chooseDate(context, today, selected);
              }
            },
          ),
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

  Future<void> _chooseDate(
    BuildContext context,
    DateTime today,
    DateTime selected,
  ) async {
    final date = await showTafaqodDateSheet(
      context,
      title: context.tr('medications.effective_from'),
      initialDate: selected,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (date == null) return;
    data.effectiveFromOn = date;
    onChanged();
  }
}
