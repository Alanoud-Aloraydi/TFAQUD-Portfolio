import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/widgets/contact_verified_badge.dart';
import 'package:flutter/material.dart';

/// What an emergency contact's tile says: the name with whether the number
/// uses تفقُد, then the relation and the number.
class ContactTileLines extends StatelessWidget {
  const ContactTileLines({super.key, required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? grey = text.bodyMedium?.copyWith(
      color: context.tokens.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            Text(contact.name, style: text.titleMedium),
            ContactVerifiedBadge(verified: contact.verified),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Text(MedicalTexts.relation(context, contact), style: grey),
            // A number reads left to right inside Arabic text.
            Text(
              MedicalTexts.phone(contact),
              textDirection: TextDirection.ltr,
              style: grey,
            ),
          ],
        ),
      ],
    );
  }
}
