import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The patient's data as label-value lines. The blood type is set left to
/// right on its own, so the page never reverses it. The emergency contacts
/// are not written: their names and numbers stay inside the app.
RecordPdfSection patientSection(BuildContext context, MedicalFile file) =>
    RecordPdfSection(
      title: context.tr('record_export.medical_file'),
      rows: <RecordPdfRow>[
        RecordPdfRow(
          label: context.tr('circles.name'),
          value: file.patient.fullName,
        ),
        RecordPdfRow(
          label: context.tr('circles.birth_date'),
          value: formatBirthDate(context, file.patient.birthDate),
        ),
        RecordPdfRow(
          label: context.tr('circles.city'),
          value: file.patient.city,
        ),
        RecordPdfRow(
          label: context.tr('circles.blood_type'),
          value: MedicalTexts.bloodType(context, file.profile.bloodType),
          ltr: file.profile.bloodType != null,
        ),
        RecordPdfRow(
          label: context.tr('circles.allergies_title'),
          value: MedicalTexts.allergies(context, file.profile.allergies),
        ),
        RecordPdfRow(
          label: context.tr('circles.conditions'),
          value: MedicalTexts.conditions(context, file.profile.conditions),
        ),
      ],
    );
