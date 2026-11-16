import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The text under a group of chips that «أخرى» asks for. [invalid] marks it
/// red once the person tried to save it empty.
class MedicalOtherField extends StatelessWidget {
  const MedicalOtherField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.invalid,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) => LabeledTextField(
    label: context.tr('circles.other_hint'),
    controller: controller,
    maxLength: MedicalOptions.otherMaxLength,
    textInputAction: TextInputAction.done,
    onChanged: onChanged,
    errorText: invalid ? context.tr('common.field_required') : null,
  );
}
