import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:flutter/material.dart';

/// The medicine of the late dose card: its photo, its name and what to
/// take.
class SimplifiedLateDoseMedicine extends StatelessWidget {
  const SimplifiedLateDoseMedicine({
    super.key,
    required this.task,
    required this.day,
  });

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        MedicinePhoto(
          circleId: day.circleId,
          planId: task.dose!.planId,
          height: 124,
          width: 124,
          radius: 30,
          iconSize: 48,
        ),
        const SizedBox(height: 12),
        Text(
          task.dose!.name,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.name),
        ),
        Text(
          simplifiedDoseAmount(context, task.dose!),
          style: SimplifiedStyle.head(SimplifiedStyle.headline),
        ),
        if (simplifiedDoseReason(task, day) == null)
          Text(
            simplifiedStrength(context, task.dose!),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
      ],
    );
  }
}
