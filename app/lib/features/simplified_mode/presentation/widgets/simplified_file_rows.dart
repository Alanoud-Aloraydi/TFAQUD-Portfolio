import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The patient's saved answers as label and value, in the order the
/// simplified file shows them.
List<(String, String)> simplifiedFileRows(
  BuildContext context,
  MedicalFile file,
) => <(String, String)>[
  (context.tr('simplified_mode.file.name'), file.patient.fullName),
  (
    context.tr('simplified_mode.file.birth_date'),
    formatBirthDate(context, file.patient.birthDate),
  ),
  (
    context.tr('simplified_mode.file.blood_type'),
    MedicalTexts.bloodType(context, file.profile.bloodType),
  ),
  (
    context.tr('simplified_mode.file.allergies'),
    MedicalTexts.allergies(context, file.profile.allergies),
  ),
  (
    context.tr('simplified_mode.file.conditions'),
    MedicalTexts.conditions(context, file.profile.conditions),
  ),
  (context.tr('simplified_mode.file.city'), file.patient.city),
];
