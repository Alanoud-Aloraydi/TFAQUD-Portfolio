import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show SharedSnooze;
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The line of a task put off ([text], from [simplifiedSnoozed]). When
/// someone of the family put it off, their photo comes before their name:
/// «التذكير مؤجّل إلى 2:09 مساءً، [photo] لين».
class SimplifiedSnoozedLine extends StatelessWidget {
  const SimplifiedSnoozedLine({
    super.key,
    required this.text,
    required this.task,
    required this.day,
    required this.style,
  });

  final String text;
  final TodayTask task;
  final SimplifiedDay day;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final SharedSnooze? shared = task.dose?.snooze ?? task.measurement?.snooze;
    final String? name = shared?.byName;
    if (shared == null || name == null) return Text(text, style: style);
    final String at = simplifiedClockAt(context, shared.remindAt);
    final String by = context.tr(
      'simplified_mode.snoozed_by',
      args: <String>[at, name],
    );
    // This phone's own snooze, or one without a name, says it in words.
    // The comma of «…، لين» is the photo's place.
    if (text != by) return Text(text, style: style);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        Text(
          context.tr('simplified_mode.snoozed_shared', args: <String>[at]),
          style: style,
        ),
        PersonPhoto(
          name: name,
          photoPath: personPhotoPath(day.circleId, shared.byAccountId),
          avatarCode: shared.byAvatarCode,
          size: 26,
        ),
        Text(name, style: style),
      ],
    );
  }
}
