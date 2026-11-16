import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «صلة القرابة»: one chip per relation, and the red line under them once
/// the person tried to save without choosing one.
List<Widget> contactRelationChips(
  BuildContext context,
  ContactFormProps props,
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
  ];
}
