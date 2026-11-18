import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_contact_edit_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_contact_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

class SimplifiedMedicalFileContactCard extends StatelessWidget {
  const SimplifiedMedicalFileContactCard({
    super.key,
    required this.contact,
    this.onEdit,
  });

  final EmergencyContact contact;

  /// Opens this contact in the form. Null while another form is open, so
  /// only one contact is being changed at a time.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    return SimplifiedCard(
      padding: const EdgeInsets.all(SimplifiedStyle.gap),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: SimplifiedColors.accentTint,
              child: Text(
                contact.name.characters.firstOrNull ?? '',
                style: SimplifiedStyle.head(SimplifiedStyle.title),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            // The card names the contact; it does not call them, so it
            // does not say «اتصل بـ». «تعديل» stays a stop of its own.
            child: Semantics(
              label: spoken(
                SimplifiedContactLines.of(context, contact).join('، '),
              ),
              excludeSemantics: true,
              child: SimplifiedContactLines(contact: contact),
            ),
          ),
          if (onEdit case final VoidCallback edit)
            SimplifiedContactEditButton(contact: contact, onEdit: edit),
        ],
      ),
    );
  }
}
