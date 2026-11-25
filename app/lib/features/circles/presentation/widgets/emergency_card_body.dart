import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_lines.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_medicines_content.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// A thin line between the parts of the card, 12 above and below.
class EmergencyRule extends StatelessWidget {
  const EmergencyRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: AppSizes.divider,
        color: AppSemanticColors.segmentTrack,
      ),
    );
  }
}

/// The current medicines: the name and strength at the start, the dose
/// times at the end.
class EmergencyMedicines extends StatelessWidget {
  const EmergencyMedicines({super.key, required this.words});

  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MedicationsCubit, MedicationsState>(
        builder: (BuildContext context, MedicationsState state) {
          final DateTime today = PatientClockScope.of(context).today();
          final List<MedicationPlan> current = state.plans
              .where(
                (MedicationPlan plan) =>
                    !plan.isPreviousOn(today) && !plan.isScheduledOn(today),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                words.t('current_medications'),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppSemanticColors.textSupporting),
              ),
              const SizedBox(height: AppSpacing.sm),
              emergencyMedicinesContent(
                context,
                state: state,
                current: current,
                words: words,
              ),
            ],
          );
        },
      );
}

/// The red badge at the top of the card and «للقراءة فقط» beside it.
class EmergencyCardTop extends StatelessWidget {
  const EmergencyCardTop({super.key, required this.words});

  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      children: <Widget>[
        EmergencyBadge(label: words.t('title')),
        const Spacer(),
        Icon(
          NoticeIcons.lock,
          size: AppSizes.iconSmall,
          color: context.tokens.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          words.t('read_only'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/// The red capsule «بطاقة الطوارئ» with the first-aid mark.
class EmergencyBadge extends StatelessWidget {
  const EmergencyBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.statusError,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            CareIcons.firstAid,
            size: AppSizes.iconSmall,
            color: AppSemanticColors.surfaceContent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppSemanticColors.surfaceContent),
          ),
        ],
      ),
    );
  }
}

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
