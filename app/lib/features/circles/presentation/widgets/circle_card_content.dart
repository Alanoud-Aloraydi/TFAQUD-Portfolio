import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/presentation/widgets/circle_app_mode_row.dart';
import 'package:app/features/circles/presentation/widgets/circle_card_name.dart';
import 'package:app/features/circles/presentation/widgets/circle_facts.dart';
import 'package:app/features/circles/presentation/widgets/patient_photo_button.dart';
import 'package:flutter/material.dart';

/// What the patient card holds, in order: the picture beside the names, the
/// facts from the medical file when it could be read, and the app mode the
/// patient was given.
List<Widget> circleCardContent(
  BuildContext context, {
  required String circleId,
  required String circleName,
  required CircleOverview overview,
  required MedicalProfileDraft? profile,
}) => <Widget>[
  Row(
    children: <Widget>[
      PatientPhotoButton(circleId: circleId, overview: overview),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: CircleCardName(name: circleName, overview: overview),
      ),
    ],
  ),
  if (profile != null) ...<Widget>[
    const SizedBox(height: AppSpacing.md),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: circleFacts(context, profile),
    ),
  ],
  const SizedBox(height: AppSpacing.md),
  const Divider(height: AppSizes.divider),
  const SizedBox(height: AppSpacing.md),
  CircleAppModeRow(mode: overview.appMode, usesApp: overview.patientUsesApp),
];
