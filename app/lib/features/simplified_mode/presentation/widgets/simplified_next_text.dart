import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_details.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// What the next card says under its picture: when, the time, the name and
/// what to take.
class SimplifiedNextText extends StatelessWidget {
  const SimplifiedNextText({
    super.key,
    required this.task,
    required this.day,
    required this.when,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «التالي، بعد ساعتين», or what the task was put off to.
  final String when;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SimplifiedStyle.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SimplifiedSnoozedLine(
            text: when,
            task: task,
            day: day,
            style: SimplifiedStyle.label(
              SimplifiedStyle.caption,
              color: task.status == TodayTaskStatus.late
                  ? SimplifiedColors.attentionInk
                  : SimplifiedColors.muted,
            ),
          ),
          Text(
            simplifiedTime(context, task.time),
            style: SimplifiedStyle.head(SimplifiedStyle.time, height: 1.1),
          ),
          const Divider(height: 28, color: SimplifiedColors.line),
          Text(
            simplifiedTaskTitle(context, task),
            style: SimplifiedStyle.head(SimplifiedStyle.name),
          ),
          SimplifiedTaskDetails(task: task, day: day),
        ],
      ),
    );
  }
}
