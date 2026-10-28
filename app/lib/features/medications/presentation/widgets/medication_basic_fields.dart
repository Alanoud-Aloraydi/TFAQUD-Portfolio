import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Column(
      children: [
        LabeledTextField(
          label: context.tr('medications.name'),
          helperText: context.tr('medications.name_helper'),
          controller: data.name,
          focusNode: data.nameFocus,
          errorText: issue?.field == MedicationFormField.name
              ? context.tr('medications.field_required')
              : null,
          maxLength: 50,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LabeledTextField(
                label: context.tr('medications.strength'),
                controller: data.strength,
                focusNode: data.strengthFocus,
                errorText: issue?.field == MedicationFormField.strength
                    ? context.tr('medications.positive_number')
                    : null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<StrengthUnit>(
                initialValue: data.strengthUnit,
                decoration: InputDecoration(
                  labelText: context.tr('medications.strength_unit'),
                ),
                items: [
                  for (final unit in StrengthUnit.values)
                    DropdownMenuItem(value: unit, child: Text(unit.apiValue)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  data.strengthUnit = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<DosageForm>(
          initialValue: data.form,
          decoration: InputDecoration(
            labelText: context.tr('medications.dosage_form'),
          ),
          items: [
            for (final value in DosageForm.values)
              DropdownMenuItem(
                value: value,
                child: Text(context.tr('medications.form.${value.name}')),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            data.form = value;
            final allowed = value.doseUnits;
            for (final schedule in data.schedules) {
              if (!allowed.contains(schedule.doseUnit)) {
                schedule.doseUnit = value.defaultDoseUnit;
              }
            }
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('medications.reason'),
          controller: data.reason,
          maxLength: 100,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('medications.instructions'),
          controller: data.instructions,
          maxLength: 250,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
