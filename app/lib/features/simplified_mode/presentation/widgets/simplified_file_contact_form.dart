import 'dart:async';

import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/contact_dialogs.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_card.dart';
import 'package:app/features/circles/presentation/widgets/contact_form_props.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The detailed mode's contact form at this mode's size. [savedName] is the
/// name the contact has now, for the question asked before it is deleted;
/// it is null for a contact being added.
Widget simplifiedFileContactForm(
  BuildContext context,
  ContactForm form,
  String? savedName,
) {
  final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
  final String? contactId = form.contactId;
  return SimplifiedDetailScale(
    child: ContactFormCard(
      // A new key for each contact, so the fields start from its values.
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
            : () => unawaited(_delete(context, cubit, savedName)),
      ),
    ),
  );
}

Future<void> _delete(
  BuildContext context,
  MedicalFileCubit cubit,
  String name,
) async {
  final bool? agreed = await showDeleteContactDialog(context, name);
  if (agreed == true) await cubit.deleteContact();
}
