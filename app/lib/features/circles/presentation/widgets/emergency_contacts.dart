import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/circles/presentation/widgets/emergency_contact_row.dart';
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
