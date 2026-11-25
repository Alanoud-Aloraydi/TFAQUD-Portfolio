import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/circles/presentation/widgets/medical_contact_form.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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

/// One emergency contact of the medical file: their picture, the name with
/// «متحقق» or «غير متحقق», the relation and the number, and a pencil that
/// opens the form of the contact.
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.circleId,
    this.onEdit,
  });

  final EmergencyContact contact;

  /// For a member's photo.
  final String circleId;

  /// Null hides the pencil (a form is open and one contact is edited at a
  /// time).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
    ),
    decoration: AppSurfaces.card(),
    child: Row(
      children: <Widget>[
        ContactTilePhoto(contact: contact, circleId: circleId),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: ContactTileLines(contact: contact)),
        if (onEdit case final VoidCallback edit)
          EditAction.pen(
            onPressed: edit,
            tooltip: context.tr(
              'circles.contact_edit_action',
              args: <String>[contact.name],
            ),
          ),
      ],
    ),
  );
}

/// The picture of an emergency contact: a circle member's, else the first
/// letter of their name. The name is read from the line beside it, so the
/// picture itself says nothing.
class ContactTilePhoto extends StatelessWidget {
  const ContactTilePhoto({
    super.key,
    required this.contact,
    required this.circleId,
  });

  final EmergencyContact contact;
  final String circleId;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: contact.accountId != null || contact.avatarCode != null
        ? PersonPhoto(
            name: contact.name,
            photoPath: contact.accountId == null
                ? ''
                : personPhotoPath(circleId, contact.accountId),
            avatarCode: contact.avatarCode,
            size: AppSizes.avatar,
          )
        : CircleAvatar(
            backgroundColor: AppSemanticColors.selectedSurface,
            foregroundColor: AppSemanticColors.textPrimary,
            child: Text(
              contact.initial,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppSemanticColors.textPrimary),
            ),
          ),
  );
}

/// What an emergency contact's tile says: the name with whether the number
/// uses تفقُد, then the relation and the number.
class ContactTileLines extends StatelessWidget {
  const ContactTileLines({super.key, required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? grey = text.bodyMedium?.copyWith(
      color: context.tokens.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            Text(contact.name, style: text.titleMedium),
            ContactVerifiedBadge(verified: contact.verified),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Text(MedicalTexts.relation(context, contact), style: grey),
            // A number reads left to right inside Arabic text.
            Text(
              MedicalTexts.phone(contact),
              textDirection: TextDirection.ltr,
              style: grey,
            ),
          ],
        ),
      ],
    );
  }
}
