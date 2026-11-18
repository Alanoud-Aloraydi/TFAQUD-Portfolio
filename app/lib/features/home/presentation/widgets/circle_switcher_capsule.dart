import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/core/network/circle_endpoints.dart';

/// The capsule of the circle switcher: the patient's photo, the circle's
/// name and a down chevron.
class CircleSwitcherCapsule extends StatelessWidget {
  const CircleSwitcherCapsule({
    super.key,
    required this.selected,
    required this.onPressed,
  });

  final CareCircleSummary selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String name = selected.name;
    return GlassCapsuleButton(
      label: name,
      // Display only here: editing the patient's photo happens in the
      // circle tab, never from the switcher.
      leading: PersonPhoto(
        name: name,
        photoPath: CircleEndpoints.patientPhoto(selected.id),
        avatarCode: selected.patientAvatarCode,
        size: 26,
      ),
      semanticLabel: context.tr(
        'topbar.switch_circle',
        args: <String>[selected.name],
      ),
      icon: ArrowIcons.caretDown,
      onPressed: onPressed,
    );
  }
}
