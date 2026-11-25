import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/presentation/widgets/emergency_allergy_box.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
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

/// A small grey label over its value.
class EmergencyLine extends StatelessWidget {
  const EmergencyLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: text.bodySmall),
          Text(value, style: text.titleMedium),
        ],
      ),
    );
  }
}

/// The medical answers of the emergency card, in the card's language.
extension EmergencyCardAnswers on EmergencyCardText {
  String conditions(ConditionsDraft? answer) {
    if (answer == null) return t('unknown');
    if (answer.answer == ListAnswer.none) return t('no_conditions');
    return join(<String>[
      for (final String value in answer.codes)
        value == MedicalOptions.other
            ? (answer.other ?? '')
            : code('condition', value),
    ]);
  }

  /// The allergies that are listed, or null when there are none to show in
  /// the red box (none, or nobody answered).
  String? allergies(AllergiesDraft? answer) {
    if (answer == null || answer.answer == ListAnswer.none) return null;
    final String joined = join(<String>[
      for (final String value in answer.medication)
        value == MedicalOptions.other
            ? (answer.otherMedication ?? '')
            : code('medication', value),
      for (final String value in answer.food)
        value == MedicalOptions.other
            ? (answer.otherFood ?? '')
            : code('food', value),
    ]);
    return joined.isEmpty ? null : joined;
  }

  String noAllergies(AllergiesDraft? answer) =>
      answer == null ? t('unknown') : t('no_allergies');
}
