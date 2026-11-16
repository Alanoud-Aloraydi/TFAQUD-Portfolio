import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_identity.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_lines.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_top.dart';
import 'package:app/features/circles/presentation/widgets/emergency_contacts.dart';
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
          EmergencyCardTop(words: words),
          const SizedBox(height: AppSpacing.md),
          EmergencyCardIdentity(
            fullName: card.fullName,
            birthDate: birthDate,
            bloodType: card.profile.bloodType,
            words: words,
          ),
          const SizedBox(height: AppSpacing.md),
          ...emergencyCardLines(words, card.profile),
          const EmergencyRule(),
          EmergencyMedicines(words: words),
          const EmergencyRule(),
          EmergencyContacts(contacts: card.contacts, words: words),
          const SizedBox(height: AppSpacing.md),
          Text(
            words.t('updated'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
