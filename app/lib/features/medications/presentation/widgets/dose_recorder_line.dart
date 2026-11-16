import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/material.dart';

/// Who answered a recorded dose, with their photo beside the name. Shown
/// only inside a circle ([circleId]) and only once the server sent a name,
/// so a dose from before this was tracked keeps its three lines.
List<Widget> doseRecorderLine(
  BuildContext context, {
  required DoseRecord record,
  String? circleId,
}) {
  if (circleId == null) return const <Widget>[];
  final String? name = record.recordedByName;
  if (name == null) return const <Widget>[];
  return <Widget>[
    const SizedBox(height: AppSpacing.xs),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonPhoto(
          name: name,
          photoPath: personPhotoPath(circleId, record.recordedByAccountId),
          avatarCode: record.recordedByAvatarCode,
          size: AppSizes.iconSmall,
        ),
        const SizedBox(width: AppSpacing.tight),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  ];
}
