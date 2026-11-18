import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The bell line of a measurement task that someone put off: when it will
/// remind again [text], and who put it off, with their picture.
class MeasurementTaskSnooze extends StatelessWidget {
  const MeasurementTaskSnooze({
    super.key,
    required this.task,
    required this.text,
    required this.circleId,
  });

  final MeasurementOccurrence task;
  final String text;
  final String circleId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(CupertinoIcons.bell_fill, size: AppSizes.iconSmall),
        const SizedBox(width: AppSpacing.tight),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
        // Who put it off, with their picture beside their name.
        if (task.snooze?.byName case final String name) ...<Widget>[
          const SizedBox(width: AppSpacing.tight),
          PersonPhoto(
            name: name,
            photoPath: task.snooze?.byAccountId == null
                ? ''
                : personPhotoPath(circleId, task.snooze!.byAccountId),
            avatarCode: task.snooze?.byAvatarCode,
            size: AppSizes.iconSmall,
          ),
        ],
      ],
    ),
  );
}
