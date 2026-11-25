import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_contact_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_focus.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_medical_file_contact_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «من أتصل بهم»: the people to call, with the open form in the place of
/// the one being changed, and the button that adds another.
List<Widget> simplifiedFileContacts(
  BuildContext context,
  MedicalFileState state,
  MedicalFile? file,
) {
  final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
  final ContactForm? form = state.form;
  return <Widget>[
    Text(
      context.tr('simplified_mode.file.contacts'),
      style: SimplifiedStyle.head(SimplifiedStyle.title),
    ),
    if (file != null && file.contacts.isEmpty)
      Text(
        context.tr('simplified_mode.file.contacts_empty'),
        style: SimplifiedStyle.text(SimplifiedStyle.body),
      ),
    for (final EmergencyContact contact
        in file?.contacts ?? const <EmergencyContact>[])
      if (form?.contactId == contact.id)
        simplifiedFileContactForm(context, form!, contact.name)
      else
        SimplifiedMedicalFileContactCard(
          contact: contact,
          // One form at a time, as in the detailed mode.
          onEdit: form == null ? () => cubit.startEdit(contact.id) : null,
        ),
    ...simplifiedFileAddContact(context, form, file, cubit),
  ];
}

/// The form of a contact being added, else the button that starts one while
/// the file can still hold another.
List<Widget> simplifiedFileAddContact(
  BuildContext context,
  ContactForm? form,
  MedicalFile? file,
  MedicalFileCubit cubit,
) {
  if (form != null && form.isNew) {
    return <Widget>[simplifiedFileContactForm(context, form, null)];
  }
  if (form != null || file == null || !file.canAddContact) {
    return const <Widget>[];
  }
  return <Widget>[
    OutlinedButton(
      onPressed: cubit.startAdd,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: const StadiumBorder(),
        side: const BorderSide(color: SimplifiedColors.control, width: 1.5),
        foregroundColor: SimplifiedColors.ink,
      ),
      child: Text(
        context.tr('simplified_mode.file.add_contact'),
        style: SimplifiedStyle.label(SimplifiedStyle.body),
      ),
    ),
  ];
}

/// The detailed mode's own contact form, whole, at this mode's size: with
/// «اختر من أعضاء الدائرة», so a member of the circle is picked by their
/// photo and name instead of typed. [savedName] is the name the contact
/// has now, for the question asked before it is deleted; it is null for a
/// contact being added.
Widget simplifiedFileContactForm(
  BuildContext context,
  ContactForm form,
  String? savedName,
) => SimplifiedDetailScale(
  child: medicalContactForm(
    context,
    context.read<MedicalFileCubit>(),
    form,
    savedName,
  ),
);
