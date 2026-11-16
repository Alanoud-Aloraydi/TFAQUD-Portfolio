import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/widgets/medical_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «فصيلة الدم»: one chip per blood type, one of them chosen.
Widget bloodTypeSection(
  BuildContext context, {
  required MedicalForm form,
  required MedicalFileEditCubit cubit,
}) => MedicalSection(
  title: context.tr('circles.blood_type'),
  child: OptionChips(
    options: <ChipOption>[
      for (final String type in MedicalOptions.bloodTypes)
        ChipOption(type, MedicalTexts.bloodTypeLabel(type)),
    ],
    isSelected: (String code) => code == form.bloodType,
    onTap: cubit.chooseBloodType,
  ),
);
