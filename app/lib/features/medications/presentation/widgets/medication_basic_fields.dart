import 'package:app/core/widgets/inset_group.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The medicine's details as one iOS grouped section: name, strength with
/// its unit, dosage form, reason and general instructions.
class MedicationBasicFields extends StatelessWidget {
  const MedicationBasicFields({
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
    return InsetGroup(
      header: context.tr('medications.basic_details'),
      children: <Widget>[
        InsetTextRow(
          label: context.tr('medications.name'),
          hint: context.tr('medications.name_hint'),
          controller: data.name,
          focusNode: data.nameFocus,
          errorText: issue?.field == MedicationFormField.name
              ? context.tr('medications.field_required')
              : null,
          maxLength: 50,
          onChanged: (_) => onChanged(),
        ),
        InsetTextRow(
          label: context.tr('medications.strength'),
          hint: context.tr('medications.strength_hint'),
          controller: data.strength,
          focusNode: data.strengthFocus,
          errorText: issue?.field == MedicationFormField.strength
              ? context.tr('medications.positive_number')
              : null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (_) => onChanged(),
          trailing: InsetChoiceButton(
            label: data.strengthUnit.apiValue,
            semanticLabel:
                '${context.tr('medications.strength_unit')}: ${data.strengthUnit.apiValue}',
            onPressed: () => _chooseStrengthUnit(context),
          ),
        ),
        InsetRow(
          label: context.tr('medications.dosage_form'),
          value: context.tr('medications.form.${data.form.name}'),
          showChevron: true,
          onTap: () => _chooseForm(context),
        ),
        InsetTextRow(
          label: context.tr('medications.reason'),
          hint: context.tr('medications.optional'),
          controller: data.reason,
          maxLength: 100,
          onChanged: (_) => onChanged(),
        ),
        InsetTextRow(
          label: context.tr('medications.instructions'),
          hint: context.tr('medications.optional'),
          controller: data.instructions,
          maxLength: 250,
          maxLines: 3,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  Future<void> _chooseStrengthUnit(BuildContext context) async {
    final StrengthUnit? unit = await showOptionSheet<StrengthUnit>(
      context,
      title: context.tr('medications.strength_unit'),
      options: StrengthUnit.values,
      labelOf: (StrengthUnit unit) => unit.apiValue,
      selected: data.strengthUnit,
    );
    if (unit == null) return;
    data.strengthUnit = unit;
    onChanged();
  }

  Future<void> _chooseForm(BuildContext context) async {
    final DosageForm? form = await showOptionSheet<DosageForm>(
      context,
      title: context.tr('medications.dosage_form'),
      options: DosageForm.values,
      labelOf: (DosageForm form) => context.tr('medications.form.${form.name}'),
      selected: data.form,
    );
    if (form == null) return;
    data.form = form;
    // A schedule keeps its unit only if the new form allows it.
    final List<DoseUnit> allowed = form.doseUnits;
    for (final schedule in data.schedules) {
      if (!allowed.contains(schedule.doseUnit)) {
        schedule.doseUnit = form.defaultDoseUnit;
      }
    }
    onChanged();
  }
}
