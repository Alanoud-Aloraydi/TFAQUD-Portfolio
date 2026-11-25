import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/layout/inset_choice_button.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// How strong the medicine is, with the unit beside the number: 500 ملغ.
class MedicationStrengthRow extends StatelessWidget {
  const MedicationStrengthRow({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  @override
  Widget build(BuildContext context) {
    final String unit = context.tr(
      'medications.strength_display.${data.strengthUnit.name}',
    );
    return InsetTextRow(
      label: context.tr('medications.strength'),
      hint: context.tr('medications.strength_hint'),
      controller: data.strength,
      focusNode: data.strengthFocus,
      errorText: issue?.field == MedicationFormField.strength
          ? context.tr('medications.positive_number')
          : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        const WesternDigitsFormatter(decimal: true),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: (_) => onChanged(),
      trailing: InsetChoiceButton(
        label: unit,
        semanticLabel: '${context.tr('medications.strength_unit')}: $unit',
        onPressed: () => _chooseUnit(context),
      ),
    );
  }

  Future<void> _chooseUnit(BuildContext context) async {
    final StrengthUnit? unit = await showOptionSheet<StrengthUnit>(
      context,
      title: context.tr('medications.strength_unit'),
      options: StrengthUnit.values,
      labelOf: (StrengthUnit unit) =>
          context.tr('medications.strength_display.${unit.name}'),
      selected: data.strengthUnit,
    );
    if (unit == null) return;
    data.strengthUnit = unit;
    onChanged();
  }
}

/// «عن الدواء»: why it is taken, how to take it, and when a dose counts as
/// missed. The reason and the instructions appear only when they were
/// written.
Widget medicationAboutGroup(BuildContext context, MedicationVersion version) {
  return PlanFactGroup(
    title: context.tr('plan_details.about_medicine'),
    children: <Widget>[
      if (version.reason case final String reason)
        PlanFact(
          icon: CareIcons.firstAid,
          label: context.tr('medications.reason'),
          value: reason,
        ),
      if (version.instructions case final String instructions)
        PlanFact(
          icon: NoticeIcons.info,
          label: context.tr('medications.instructions'),
          value: instructions,
        ),
      PlanFact(
        icon: PeopleIcons.hourglass,
        label: context.tr('medications.missed_after'),
        value: arabicCount(
          context,
          ArabicCount.minutes,
          version.missedAfterMinutes,
        ),
      ),
    ],
  );
}
