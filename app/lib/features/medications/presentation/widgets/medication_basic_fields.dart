import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationBasicFields extends StatelessWidget {
  const MedicationBasicFields({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LabeledTextField(
          label: context.tr('medications.name'),
          controller: data.name,
          maxLength: 50,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('medications.strength'),
          controller: data.strength,
          maxLength: 50,
          onChanged: (_) => onChanged(),
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
