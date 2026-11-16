import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The contact's name and number, and whatever went wrong on the last save.
List<Widget> contactNamePhoneFields(
  BuildContext context,
  ContactFormProps props,
  ContactFormText typed,
) => <Widget>[
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
  PhoneField(
    controller: typed.phone,
    label: context.tr('circles.contact_phone'),
    autofocus: false,
    showError: props.form.showErrors && !props.form.phoneValid,
    onChanged: (String text) => props.onPhone(ArabicDigits.digitsOnly(text)),
  ),
  if (props.form.errorKey != null) ...<Widget>[
    const SizedBox(height: AppSpacing.md),
    InlineError(messageKey: props.form.errorKey!),
  ],
];
