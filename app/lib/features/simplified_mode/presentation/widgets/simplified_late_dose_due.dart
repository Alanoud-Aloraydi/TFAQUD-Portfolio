import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_late_dose_lines.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// How the late dose is taken and how late it is: its chips, when it was
/// due, and what it was put off to.
class SimplifiedLateDoseDue extends StatelessWidget {
  const SimplifiedLateDoseDue({
    super.key,
    required this.task,
    required this.day,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «سأذكّرك 2:09 مساءً» when the dose is put off.
  final String? snoozed;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = simplifiedTaskChips(context, task, day);
    return Column(
      children: <Widget>[
        if (chips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final String chip in chips) SimplifiedChip(chip),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          simplifiedLateDoseWasDue(context, task),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            color: SimplifiedColors.attentionInk,
            weight: AppTextTheme.bold,
          ),
        ),
        if (snoozed case final String text)
          SimplifiedSnoozedLine(
            text: text,
            task: task,
            day: day,
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              color: SimplifiedColors.ink,
              weight: AppTextTheme.medium,
            ),
          ),
      ],
    );
  }
}
