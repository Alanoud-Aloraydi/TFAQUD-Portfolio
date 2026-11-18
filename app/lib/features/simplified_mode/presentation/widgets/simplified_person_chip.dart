import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// Someone of the circle on a label: their photo first, then their name,
/// so the patient knows who it is before reading.
class SimplifiedPersonChip extends StatelessWidget {
  const SimplifiedPersonChip({
    super.key,
    required this.circleId,
    required this.accountId,
    required this.name,
    this.avatarCode,
    this.onDark = false,
  });

  final String circleId;
  final String? accountId;
  final String name;
  final String? avatarCode;

  /// On the dark ground of a full-screen reminder.
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
    decoration: BoxDecoration(
      color: onDark
          ? SimplifiedColors.surface.withValues(alpha: .14)
          : SimplifiedColors.chip,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: PersonPhoto(
            name: name,
            photoPath: personPhotoPath(circleId, accountId),
            avatarCode: avatarCode,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            style: SimplifiedStyle.label(
              SimplifiedStyle.caption,
              color: onDark ? SimplifiedColors.surface : SimplifiedColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
