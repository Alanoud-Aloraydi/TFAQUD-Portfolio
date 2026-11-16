import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/contact_choice.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/contact_member_chip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
