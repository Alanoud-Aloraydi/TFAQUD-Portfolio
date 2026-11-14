import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedMedicalFileContactCard extends StatelessWidget {
  const SimplifiedMedicalFileContactCard({super.key, required this.contact});

  final EmergencyContact contact;

  /// What the card says: the name, then who they are to the patient.
  static List<String> lines(BuildContext context, EmergencyContact contact) =>
      <String>[contact.name, MedicalTexts.relation(context, contact)];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'simplified_mode.a11y.call_contact',
        args: <String>[contact.name, MedicalTexts.relation(context, contact)],
      ),
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return SimplifiedCard(
      padding: const EdgeInsets.all(SimplifiedStyle.gap),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: SimplifiedStyle.accentTint,
            child: Text(
              contact.name.characters.firstOrNull ?? '',
              style: SimplifiedStyle.head(SimplifiedStyle.title),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
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
        ],
      ),
    );
  }
}
