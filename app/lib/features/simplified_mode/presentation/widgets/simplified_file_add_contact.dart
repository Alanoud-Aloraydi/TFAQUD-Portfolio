import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_contact_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

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
