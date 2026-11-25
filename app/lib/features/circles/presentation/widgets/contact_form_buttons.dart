import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/contact_member_chip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «حفظ» and «إلغاء» side by side, and «حذف» under them for a contact that
/// already exists.
List<Widget> contactFormButtons(
  BuildContext context,
  ContactFormProps props,
) => <Widget>[
  const SizedBox(height: AppSpacing.lg),
  Row(
    children: <Widget>[
      Expanded(
        child: PillButton(
          label: context.tr('circles.contact_save'),
          isLoading: props.form.saving,
          onPressed: props.onSave,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: OutlinedButton(
          onPressed: props.form.saving ? null : props.onCancel,
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(AppSizes.button),
            foregroundColor: AppSemanticColors.textPrimary,
            side: const BorderSide(color: AppSemanticColors.borderControlBase),
          ),
          child: Text(context.tr('common.cancel')),
        ),
      ),
    ],
  ),
  if (props.onDelete != null) ...<Widget>[
    const SizedBox(height: AppSpacing.sm),
    Align(
      alignment: AlignmentDirectional.centerStart,
      // Deleting is a destructive action: the error red. No start padding,
      // so the trash sits on the card's content edge.
      child: TextButton.icon(
        onPressed: props.form.saving ? null : props.onDelete,
        icon: const Icon(ActionIcons.trash, size: AppSizes.iconSmall),
        label: Text(context.tr('circles.contact_delete')),
        style: TextButton.styleFrom(
          foregroundColor: AppSemanticColors.statusError,
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        ),
      ),
    ),
  ],
];

/// The circle's members a new contact can be picked from: a tap fills the
/// name and the number with theirs. Empty for a contact that already exists.
List<Widget> contactMemberChoices(
  BuildContext context,
  ContactFormProps props, {
  required ValueChanged<ContactChoice> onPick,
}) {
  final ContactForm form = props.form;
  if (!form.isNew || props.choices.isEmpty) return const <Widget>[];
  return <Widget>[
    const SizedBox(height: AppSpacing.lg),
    Text(
      context.tr('circles.contact_from_members'),
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.tokens.textSecondary),
    ),
    const SizedBox(height: AppSpacing.sm),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final ContactChoice choice in props.choices)
          ContactMemberChip(
            choice: choice,
            circleId: props.circleId,
            selected: form.phone == choice.phone && form.name == choice.name,
            onTap: form.saving ? null : () => onPick(choice),
          ),
      ],
    ),
  ];
}
