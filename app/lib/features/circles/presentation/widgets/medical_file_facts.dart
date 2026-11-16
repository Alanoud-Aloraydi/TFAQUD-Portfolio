import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The saved answers of the medical file, one to a row.
class MedicalFileFacts extends StatelessWidget {
  const MedicalFileFacts({super.key, required this.file});

  final MedicalFile file;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: <Widget>[
      InfoRow(label: context.tr('circles.name'), value: file.patient.fullName),
      InfoRow(
        label: context.tr('circles.birth_date'),
        value: formatBirthDate(context, file.patient.birthDate),
      ),
      InfoRow(
        label: context.tr('circles.blood_type'),
        value: MedicalTexts.bloodType(context, file.profile.bloodType),
      ),
      InfoRow(
        label: context.tr('circles.allergies_title'),
        value: MedicalTexts.allergies(context, file.profile.allergies),
      ),
      InfoRow(
        label: context.tr('circles.conditions'),
        value: MedicalTexts.conditions(context, file.profile.conditions),
      ),
      InfoRow(label: context.tr('circles.city'), value: file.patient.city),
    ],
  );
}
