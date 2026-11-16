import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/presentation/widgets/emergency_allergy_box.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_answers.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_line.dart';
import 'package:flutter/material.dart';

/// The allergies — in the red box when there are any to name — and the
/// chronic conditions under them.
List<Widget> emergencyCardLines(
  EmergencyCardText words,
  MedicalProfileDraft profile,
) {
  final String? allergies = words.allergies(profile.allergies);
  return <Widget>[
    if (allergies != null)
      EmergencyAllergyBox(label: words.t('allergy'), value: allergies)
    else
      EmergencyLine(
        label: words.t('allergies'),
        value: words.noAllergies(profile.allergies),
      ),
    const SizedBox(height: AppSpacing.md),
    EmergencyLine(
      label: words.t('conditions'),
      value: words.conditions(profile.conditions),
    ),
  ];
}
