import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/contact_dialogs.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_card.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:flutter/material.dart';

/// The card that adds a contact or changes one, wired to the page's cubit.
/// [savedName] is the name the contact has now, for the question asked
/// before it is deleted; it is null for a new contact.
Widget medicalContactForm(
  BuildContext context,
  MedicalFileCubit cubit,
  ContactForm form,
  String? savedName,
) {
  final String? contactId = form.contactId;
  return ContactFormCard(
    // A new key for each contact, so the text fields start from its values.
    key: ValueKey<String>(contactId ?? 'new-contact'),
    props: ContactFormProps(
      form: form,
      onRelation: cubit.relationChosen,
      onName: cubit.nameChanged,
      onPhone: cubit.phoneChanged,
      onSave: cubit.saveContact,
      onCancel: cubit.cancelForm,
      onDelete: contactId == null || savedName == null
          ? null
          : () => _delete(context, cubit, savedName),
      choices: _members(cubit),
      onChoose: cubit.memberChosen,
      circleId: cubit.circleId,
    ),
  );
}

/// The circle's members who are not a contact yet.
List<ContactChoice> _members(MedicalFileCubit cubit) => <ContactChoice>[
  for (final ContactChoice choice
      in cubit.state.choices ?? const <ContactChoice>[])
    if (!(cubit.state.file?.contacts ?? const <EmergencyContact>[]).any(
      (EmergencyContact contact) => contact.nationalNumber == choice.phone,
    ))
      choice,
];

Future<void> _delete(
  BuildContext context,
  MedicalFileCubit cubit,
  String name,
) async {
  final bool? agreed = await showDeleteContactDialog(context, name);
  if (agreed == true) await cubit.deleteContact();
}
