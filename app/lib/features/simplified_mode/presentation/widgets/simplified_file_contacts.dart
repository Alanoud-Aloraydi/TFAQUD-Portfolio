import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_add_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_contact_form.dart';
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
