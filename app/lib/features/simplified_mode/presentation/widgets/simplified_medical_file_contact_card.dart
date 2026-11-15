import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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

  /// What the card says: the name, then who they are to the patient.
  static List<String> lines(BuildContext context, EmergencyContact contact) =>
      <String>[contact.name, MedicalTexts.relation(context, contact)];

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
              backgroundColor: SimplifiedStyle.accentTint,
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
              label: spoken(lines(context, contact).join('، ')),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    contact.name,
                    style: SimplifiedStyle.head(SimplifiedStyle.body),
                  ),
                  Text(
                    MedicalTexts.relation(context, contact),
                    style: SimplifiedStyle.text(SimplifiedStyle.caption),
                  ),
                ],
              ),
            ),
          ),
          if (onEdit case final VoidCallback edit)
            Semantics(
              button: true,
              label: spoken(
                '${context.tr('circles.contact_edit_title')}، '
                '${contact.name}',
              ),
              onTap: edit,
              excludeSemantics: true,
              child: TextButton(
                onPressed: edit,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, SimplifiedStyle.touch),
                  foregroundColor: SimplifiedStyle.ink,
                ),
                child: Text(
                  context.tr('simplified_mode.file.edit'),
                  style: SimplifiedStyle.label(SimplifiedStyle.caption),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
