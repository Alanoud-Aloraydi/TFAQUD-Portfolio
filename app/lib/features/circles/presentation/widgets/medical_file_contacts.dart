import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/widgets/contact_tile.dart';
import 'package:app/features/circles/presentation/widgets/medical_contact_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The emergency contacts: the heading, the contacts themselves with the
/// open form in the place of the one being changed, and the button that
/// adds one until the file holds as many as it can.
List<Widget> medicalFileContacts(
  BuildContext context, {
  required MedicalFileCubit cubit,
  required MedicalFile file,
  required ContactForm? form,
}) => <Widget>[
  ...medicalFileContactsHeader(
    context,
    empty: file.contacts.isEmpty && form == null,
  ),
  for (final EmergencyContact contact in file.contacts) ...<Widget>[
    if (form != null && form.contactId == contact.id)
      medicalContactForm(context, cubit, form, contact.name)
    else
      ContactTile(
        contact: contact,
        circleId: cubit.circleId,
        // One form is open at a time.
        onEdit: form == null ? () => cubit.startEdit(contact.id) : null,
      ),
    const SizedBox(height: AppSpacing.md),
  ],
  if (form != null && form.isNew)
    medicalContactForm(context, cubit, form, null),
  if (form == null && file.canAddContact)
    // In the middle, like the other add buttons of an empty list.
    Align(
      child: OutlinedButton.icon(
        onPressed: cubit.startAdd,
        icon: const Icon(ActionIcons.plus),
        label: Text(context.tr('circles.contact_add')),
      ),
    ),
  if (form == null && !file.canAddContact)
    InsetText(
      context.tr('circles.contact_max'),
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.tokens.textSecondary),
    ),
];

/// «جهات الاتصال في الطوارئ», and the note that says there are none yet.
///
/// Notes outside the cards start 16 in, lined up with the heading and the
/// text inside the cards; the cards and the button reach the edge.
List<Widget> medicalFileContactsHeader(
  BuildContext context, {
  required bool empty,
}) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
      child: Semantics(
        header: true,
        child: Text(
          context.tr('circles.file_contacts_title'),
          style: text.titleMedium,
        ),
      ),
    ),
    const SizedBox(height: AppSpacing.labelGap),
    if (empty) ...<Widget>[
      InsetText(
        context.tr('circles.file_contacts_empty'),
        style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  ];
}
