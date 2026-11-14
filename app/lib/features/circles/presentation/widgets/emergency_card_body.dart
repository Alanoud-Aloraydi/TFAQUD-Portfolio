import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/presentation/widgets/emergency_allergy_box.dart';
import 'package:app/features/circles/presentation/widgets/emergency_badge.dart';
import 'package:app/features/circles/presentation/widgets/emergency_blood_type.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_contacts.dart';
import 'package:app/features/circles/presentation/widgets/emergency_line.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicines.dart';
import 'package:app/features/circles/presentation/widgets/emergency_rule.dart';
import 'package:flutter/material.dart';

/// The card itself: white, a 2-point ink edge, 16 inside.
class EmergencyCardBody extends StatelessWidget {
  const EmergencyCardBody({
    super.key,
    required this.card,
    required this.birthDate,
    required this.words,
  });

  final EmergencyCard card;
  final DateTime? birthDate;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime? born = birthDate;
    final String? bloodType = card.profile.bloodType;
    final String? allergies = words.allergies(card.profile.allergies);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.inset),
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.m,
          side: const BorderSide(
            color: AppSemanticColors.textSupporting,
            width: AppSizes.borderEmphasis,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The red badge and «للقراءة فقط».
          Row(
            children: <Widget>[
              EmergencyBadge(label: words.t('title')),
              const Spacer(),
              Icon(
                AppIcons.lock,
                size: AppSizes.iconSmall,
                color: context.tokens.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(words.t('read_only'), style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // The name and age, and the blood type in the dark box.
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(card.fullName, style: text.headlineMedium),
                    if (born != null)
                      Text(words.age(born), style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              EmergencyBloodType(
                label: words.t('blood_type'),
                value: bloodType,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (allergies != null)
            EmergencyAllergyBox(label: words.t('allergy'), value: allergies)
          else
            EmergencyLine(
              label: words.t('allergies'),
              value: words.noAllergies(card.profile.allergies),
            ),
          const SizedBox(height: AppSpacing.md),
          EmergencyLine(
            label: words.t('conditions'),
            value: words.conditions(card.profile.conditions),
          ),
          const EmergencyRule(),
          EmergencyMedicines(words: words),
          const EmergencyRule(),
          EmergencyContacts(contacts: card.contacts, words: words),
          const SizedBox(height: AppSpacing.md),
          Text(words.t('updated'), style: text.bodySmall),
        ],
      ),
    );
  }
}
