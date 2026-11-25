import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_alert.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_contacts.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_skeleton.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// What the medical file shows under its heading: the skeleton while it
/// loads, the reason it could not be loaded, else the answers and the
/// emergency contacts. [onEdit] opens the edit page.
Widget medicalFileBody(
  BuildContext context, {
  required MedicalFileCubit cubit,
  required MedicalFileState state,
  required VoidCallback onEdit,
}) => switch (state.status) {
  MedicalFileStatus.loading => const MedicalFileSkeleton(),
  MedicalFileStatus.failure => MedicalFileFailure(
    messageKey: state.messageKey,
    onRetry: cubit.load,
  ),
  MedicalFileStatus.ready => _ready(context, cubit, state, state.file!, onEdit),
};

Widget _ready(
  BuildContext context,
  MedicalFileCubit cubit,
  MedicalFileState state,
  MedicalFile file,
  VoidCallback onEdit,
) => ListView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
  children: <Widget>[
    // A new circle has no medical answers yet: the yellow «!» says what is
    // missing and opens the edit page.
    if (file.needsFilling) ...<Widget>[
      MedicalFileAlert(gaps: file.gaps, onFill: onEdit),
      const SizedBox(height: AppSpacing.lg),
    ],
    MedicalFileFacts(file: file),
    const SizedBox(height: AppSpacing.xl),
    ...medicalFileContacts(context, cubit: cubit, file: file, form: state.form),
  ],
);

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
