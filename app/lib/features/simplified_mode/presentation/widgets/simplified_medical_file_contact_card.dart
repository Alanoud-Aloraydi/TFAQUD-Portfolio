import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_contact_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

/// The pencil beside an emergency contact, opening it in the form.
class SimplifiedContactEditButton extends StatelessWidget {
  const SimplifiedContactEditButton({
    super.key,
    required this.contact,
    required this.onEdit,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken(
        '${context.tr('circles.contact_edit_title')}، '
        '${contact.name}',
      ),
      onTap: onEdit,
      excludeSemantics: true,
      // The pencil alone, as on the detailed mode's contact.
      child: IconButton(
        onPressed: onEdit,
        constraints: const BoxConstraints(
          minWidth: SimplifiedStyle.touch,
          minHeight: SimplifiedStyle.touch,
        ),
        color: SimplifiedColors.ink,
        icon: const Icon(ActionIcons.pencil, size: 26),
      ),
    );
  }
}
