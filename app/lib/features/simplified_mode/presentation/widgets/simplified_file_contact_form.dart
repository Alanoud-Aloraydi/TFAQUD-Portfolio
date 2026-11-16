import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/widgets/medical_contact_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_detail_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
