import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A contact's facts under their name, the same four the detailed mode
/// shows: who they are to the patient, their number, and whether that
/// number uses تفقُد.
class SimplifiedContactLines extends StatelessWidget {
  const SimplifiedContactLines({super.key, required this.contact});

  final EmergencyContact contact;

  static String _verified(BuildContext context, EmergencyContact contact) =>
      context.tr(
        contact.verified
            ? 'circles.contact_verified'
            : 'circles.contact_unverified',
      );

  /// The same facts as one line, for the screen reader.
  static List<String> of(BuildContext context, EmergencyContact contact) =>
      <String>[
        contact.name,
        MedicalTexts.relation(context, contact),
        MedicalTexts.phone(contact),
        _verified(context, contact),
      ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(contact.name, style: SimplifiedStyle.head(SimplifiedStyle.body)),
      Text(
        MedicalTexts.relation(context, contact),
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
      // A number reads left to right inside Arabic text.
      Text(
        MedicalTexts.phone(contact),
        textDirection: TextDirection.ltr,
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
      Text(
        _verified(context, contact),
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
    ],
  );
}
