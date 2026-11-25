import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/next_task_action.dart';
import 'package:app/features/home/presentation/widgets/next_task_summary.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_action_dose.dart';
import 'package:flutter/material.dart';

/// «المهمة القادمة»: the dose to act on now, or the next task with the time
/// left, and what can be answered on it already ([NextTaskAction]).
class NextTaskCard extends StatelessWidget {
  const NextTaskCard({
    super.key,
    required this.task,
    required this.circleId,
    required this.canManage,
    required this.now,
  });
  final NextTask task;
  final String circleId;
  final bool canManage;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final medication = task.medication;
    final sameDay = DateUtils.isSameDay(task.at, now);
    if (medication != null && sameDay) {
      return TodayMedicationActionDose(
        occurrence: medication,
        circleId: circleId,
        canManage: canManage,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.textSupporting),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NextTaskSummary(task: task, circleId: circleId, now: now),
            NextTaskAction(
              task: task,
              circleId: circleId,
              canManage: canManage,
              now: now,
            ),
          ],
        ),
      ),
    );
  }
}
