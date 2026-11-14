import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// «اتصل بـ»: one row per person, the name and relation, the number left to
/// right, and the call mark. A tap calls.
class EmergencyContacts extends StatelessWidget {
  const EmergencyContacts({
    super.key,
    required this.contacts,
    required this.words,
  });

  final List<EmergencyContact> contacts;
  final EmergencyCardText words;

  Future<void> _call(String number) async {
    final String digits = number.replaceAll(' ', '');
    await launchUrl(Uri(scheme: 'tel', path: digits));
  }

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
            child: Material(
              color: AppSemanticColors.surfaceContent,
              shape: AppRadius.shape(AppRadius.s),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _call(MedicalTexts.phone(contact)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${contact.name} · ${words.relation(contact)}',
                          style: text.titleSmall,
                        ),
                      ),
                      Text(
                        MedicalTexts.phone(contact),
                        textDirection: TextDirection.ltr,
                        style: text.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        AppIcons.phoneCall,
                        size: AppSizes.iconSmall,
                        color: AppSemanticColors.statusSuccess,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
