import 'package:app/core/feedback/error_toast.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The contact's name and number. A number already among the contacts is
/// said under it; any other refusal of the last save is a toast.
List<Widget> contactNamePhoneFields(
  BuildContext context,
  ContactFormProps props,
  ContactFormText typed,
) {
  final String? key = props.form.errorKey;
  final String? numberError = key == 'circles.duplicate_contact'
      ? context.tr(key!)
      : null;
  return <Widget>[
    const SizedBox(height: AppSpacing.lg),
    LabeledTextField(
      label: context.tr('circles.contact_name'),
      controller: typed.name,
      maxLength: MedicalOptions.contactNameMaxLength,
      onChanged: props.onName,
      errorText: props.form.showErrors && props.form.name.trim().isEmpty
          ? context.tr('common.field_required')
          : null,
    ),
    const SizedBox(height: AppSpacing.lg),
    ErrorToast(
      errorKey: numberError == null ? key : null,
      child: PhoneField(
        controller: typed.phone,
        label: context.tr('circles.contact_phone'),
        autofocus: false,
        showError: props.form.showErrors && !props.form.phoneValid,
        error: numberError,
        onChanged: (String text) =>
            props.onPhone(ArabicDigits.digitsOnly(text)),
      ),
    ),
  ];
}
