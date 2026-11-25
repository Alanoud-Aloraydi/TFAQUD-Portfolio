import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/phone_call.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:flutter/material.dart';

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
