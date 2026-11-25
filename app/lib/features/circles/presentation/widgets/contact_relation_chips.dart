import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_opening.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «صلة القرابة»: one chip per relation, the red line under them once the
/// person tried to save without choosing one, and with «أخرى» a field for
/// the relation in their own words.
List<Widget> contactRelationChips(
  BuildContext context,
  ContactFormProps props,
  ContactFormText typed,
) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Text(
      context.tr('circles.contact_relation'),
      style: text.titleSmall?.copyWith(color: context.tokens.textSecondary),
    ),
    const SizedBox(height: AppSpacing.sm),
    OptionChips(
      options: <ChipOption>[
        for (final String code in MedicalOptions.contactRelations)
          ChipOption(code, context.tr('medical.relation.$code')),
      ],
      isSelected: (String code) => code == props.form.relation,
      onTap: props.form.saving ? (_) {} : props.onRelation,
    ),
    if (props.form.showErrors && props.form.relation == null) ...<Widget>[
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.tr('common.field_required'),
        style: text.bodySmall?.copyWith(color: AppSemanticColors.statusError),
      ),
    ],
    if (props.form.relation == MedicalOptions.other) ...<Widget>[
      const SizedBox(height: AppSpacing.md),
      LabeledTextField(
        label: context.tr('circles.contact_relation_other'),
        helperText: context.tr('circles.contact_relation_other_hint'),
        controller: typed.relationOther,
        maxLength: MedicalOptions.contactRelationMaxLength,
        onChanged: props.onRelationOther,
        errorText: props.form.relationOtherMissing
            ? context.tr('common.field_required')
            : null,
      ),
    ],
  ];
}

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
