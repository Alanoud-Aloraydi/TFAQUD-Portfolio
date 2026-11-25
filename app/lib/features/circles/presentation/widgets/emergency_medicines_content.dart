import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/phone_call.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What sits under «الأدوية الحالية»: the turning circle while the plans
/// load, a retry when they could not be read, the line that says there are
/// none, else one row per medicine.
Widget emergencyMedicinesContent(
  BuildContext context, {
  required MedicationsState state,
  required List<MedicationPlan> current,
  required EmergencyCardText words,
}) {
  if (state.status == MedicationsStatus.loading ||
      state.status == MedicationsStatus.initial) {
    return const LoadingNote();
  }
  if (state.status == MedicationsStatus.failure) {
    return TextButton(
      onPressed: () => context.read<MedicationsCubit>().load(
        context.read<EmergencyCardCubit>().circleId,
      ),
      child: Text(context.tr(state.messageKey ?? 'error.unknown')),
    );
  }
  if (current.isEmpty) {
    return Text(
      words.t('no_current_medications'),
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
  return Column(
    children: <Widget>[
      for (final MedicationPlan plan in current) ...<Widget>[
        if (plan != current.first) const SizedBox(height: AppSpacing.sm),
        EmergencyMedicine(plan: plan, words: words),
      ],
    ],
  );
}

/// One medicine on the emergency card: what it is at the start, when it is
/// taken at the end.
class EmergencyMedicine extends StatelessWidget {
  const EmergencyMedicine({super.key, required this.plan, required this.words});

  final MedicationPlan plan;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppSemanticColors.textSupporting);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: EmergencyMedicineName(
                plan: plan,
                words: words,
                small: small,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            EmergencyMedicineTimes(plan: plan, words: words, small: small),
          ],
        ),
      ),
    );
  }
}

/// A medicine's dose times, one under the other: «8:00 ص • 1 قرص», where
/// the dot keeps the time and the dose apart.
class EmergencyMedicineTimes extends StatelessWidget {
  const EmergencyMedicineTimes({
    super.key,
    required this.plan,
    required this.words,
    required this.small,
  });

  final MedicationPlan plan;
  final EmergencyCardText words;
  final TextStyle? small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      for (final MedicationSchedule schedule in plan.version.schedules)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              words.clock(schedule.time),
              textDirection: TextDirection.ltr,
              style: small,
            ),
            // Without it «2» and «11:00» read as «211:00».
            Text(' • ', style: small),
            Text(
              '${formatMedicationNumber(schedule.doseValue)} '
              '${words.unit(schedule.doseUnit.name)}',
              style: small,
            ),
          ],
        ),
    ],
  );
}

/// A medicine's name, and under it its strength and its form.
class EmergencyMedicineName extends StatelessWidget {
  const EmergencyMedicineName({
    super.key,
    required this.plan,
    required this.words,
    required this.small,
  });

  final MedicationPlan plan;
  final EmergencyCardText words;
  final TextStyle? small;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(plan.version.name, style: Theme.of(context).textTheme.titleSmall),
      // The strength is its own run, left to right, so «500 mg» never
      // turns into «mg 500».
      Wrap(
        spacing: AppSpacing.xs,
        children: <Widget>[
          Text(
            '${formatMedicationNumber(plan.version.strengthValue)} '
            '${plan.version.strengthUnit.apiValue}',
            textDirection: TextDirection.ltr,
            style: small,
          ),
          Text(words.form(plan.version.dosageForm.name), style: small),
        ],
      ),
    ],
  );
}

/// «اتصل بـ»: one row per person, or the line that says there is nobody.
class EmergencyContacts extends StatelessWidget {
  const EmergencyContacts({
    super.key,
    required this.contacts,
    required this.words,
  });

  final List<EmergencyContact> contacts;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(words.t('call'), style: text.bodySmall),
        if (contacts.isEmpty)
          Text(words.t('no_contacts'), style: text.titleSmall),
        for (final EmergencyContact contact in contacts)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: EmergencyContactRow(contact: contact, words: words),
          ),
      ],
    );
  }
}

/// One person to call: name and relation, the number left to right, and the
/// call mark; a tap calls.
class EmergencyContactRow extends StatelessWidget {
  const EmergencyContactRow({
    super.key,
    required this.contact,
    required this.words,
  });

  final EmergencyContact contact;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String number = MedicalTexts.phone(contact);
    final String who = '${contact.name}، ${words.relation(contact)}';
    return Material(
      color: AppSemanticColors.surfaceContent,
      shape: AppRadius.shape(AppRadius.s),
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: () => callNumber(number),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      who,
                      style: text.titleSmall,
                      semanticsLabel: spoken(who),
                    ),
                  ),
                  Text(
                    number,
                    textDirection: TextDirection.ltr,
                    style: text.bodySmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    PeopleIcons.phoneCall,
                    size: AppSizes.iconSmall,
                    color: AppSemanticColors.statusSuccess,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
