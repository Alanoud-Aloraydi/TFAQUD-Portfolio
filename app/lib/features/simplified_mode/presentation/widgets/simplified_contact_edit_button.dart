import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

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
