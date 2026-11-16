import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/features/circles/presentation/cubit/contact_choice.dart';
import 'package:flutter/material.dart';

/// The picture of a circle member inside the pill that picks them.
class ContactChoicePhoto extends StatelessWidget {
  const ContactChoicePhoto({
    super.key,
    required this.choice,
    required this.circleId,
  });

  /// Small enough to sit inside a pill the height of a touch area.
  static const double size = 32;

  final ContactChoice choice;
  final String circleId;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.capsule),
    child: PersonPhoto(
      name: choice.name,
      photoPath: choice.accountId == null
          ? ''
          : personPhotoPath(circleId, choice.accountId),
      avatarCode: choice.avatarCode,
      size: size,
    ),
  );
}
