import 'package:app/features/medications/domain/entities/dosage_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The form of a medicine (tablets, syrup, …) in small words under its name.
class MedicationFormText extends StatelessWidget {
  const MedicationFormText(this.form, {super.key});

  final DosageForm form;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr('medications.form.${form.name}'),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
