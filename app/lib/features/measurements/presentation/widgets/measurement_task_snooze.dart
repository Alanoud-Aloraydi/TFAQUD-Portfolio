import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
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

/// A missed task's kind and time, and its day under them, as a reading's
/// titles are.
class MeasurementTaskTitle extends StatelessWidget {
  const MeasurementTaskTitle({super.key, required this.task});

  final MeasurementOccurrence task;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${measurementKindTitle(context, task.kind)} · '
            '${clockText(task.time)}',
            style: text.titleMedium,
            semanticsLabel: spoken(
              '${measurementKindTitle(context, task.kind)}، '
              '${clockText(task.time)}',
            ),
          ),
          Text(
            formatMedicationDate(context, task.scheduledOn),
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
