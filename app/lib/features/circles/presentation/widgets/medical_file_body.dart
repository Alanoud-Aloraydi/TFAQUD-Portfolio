import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_alert.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_contacts.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_facts.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_failure.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_skeleton.dart';
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
