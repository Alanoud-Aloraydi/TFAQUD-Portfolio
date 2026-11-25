import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:flutter/material.dart';

/// Who the card is for: their name and age, and the blood type in the dark
/// box beside them.
class EmergencyCardIdentity extends StatelessWidget {
  const EmergencyCardIdentity({
    super.key,
    required this.fullName,
    required this.birthDate,
    required this.bloodType,
    required this.words,
  });

  final String fullName;
  final DateTime? birthDate;
  final String? bloodType;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime? born = birthDate;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(fullName, style: text.headlineMedium),
              if (born != null) Text(words.age(born), style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        EmergencyBloodType(label: words.t('blood_type'), value: bloodType),
      ],
    );
  }
}

/// The blood type in a dark box: the small label over the type, left to
/// right. A dash while nobody entered it.
class EmergencyBloodType extends StatelessWidget {
  const EmergencyBloodType({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: MergeSemantics(
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: AppSemanticColors.onInkSupporting,
              ),
            ),
            Text(
              value ?? '—',
              textDirection: TextDirection.ltr,
              style: text.headlineMedium?.copyWith(
                color: AppSemanticColors.surfaceContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
