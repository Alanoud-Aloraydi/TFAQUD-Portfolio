import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_done.dart';
import 'package:flutter/material.dart';

/// A done task's last line: «تم 4:30 مساءً»، then the photo of who
/// pressed it, then their name alone («سارة»), so the patient sees at a
/// glance when, and by whom, before reading the name.
class SimplifiedDoneLine extends StatelessWidget {
  const SimplifiedDoneLine({
    super.key,
    required this.task,
    required this.day,
    required this.style,
  });

  final TodayTask task;
  final SimplifiedDay day;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final SimplifiedDone? done = simplifiedDone(task);
    final String at = simplifiedDoneAt(context, done);
    final String? by = simplifiedDoneBy(context, done, day);
    if (done == null || by == null) return Text(at, style: style);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        Text('$at،', style: style),
        PersonPhoto(
          name: done.name ?? '',
          photoPath: personPhotoPath(day.circleId, done.accountId),
          avatarCode: done.avatarCode,
          size: 26,
        ),
        Text(by, style: style),
      ],
    );
  }
}
