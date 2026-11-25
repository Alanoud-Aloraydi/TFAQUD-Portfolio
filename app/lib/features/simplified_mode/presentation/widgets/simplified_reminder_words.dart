import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the reminder asks, read as one sentence: «حان وقت»، the task's
/// name, its line, who comes along, and its short notes.
class SimplifiedReminderWords extends StatelessWidget {
  const SimplifiedReminderWords({super.key, required this.content});

  final SimplifiedReminderContent content;

  static const Color _ink = SimplifiedColors.surface;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      children: <Widget>[
        Text(content.lead, style: SimplifiedStyle.text(28, color: _ink)),
        Text(
          content.name,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.hero, color: _ink),
        ),
        const SizedBox(height: 10),
        Text(
          content.line,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.headline, color: _ink),
        ),
        if (content.people case final Widget people) ...<Widget>[
          const SizedBox(height: 12),
          people,
        ],
        if (content.chips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final String chip in content.chips)
                SimplifiedChip(chip, onDark: true),
            ],
          ),
        ],
      ],
    ),
  );
}

/// The reminder's one or two round answers: the task's own («أخذته»,
/// «حضرت») and, when it can be put off, «ذكّرني لاحقًا».
class SimplifiedReminderAnswers extends StatelessWidget {
  const SimplifiedReminderAnswers({super.key, required this.content});

  final SimplifiedReminderContent content;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SimplifiedReminderRoundAnswer(
        label: content.yesLabel,
        icon: ActionIcons.check,
        fill: SimplifiedColors.accent,
        ink: SimplifiedColors.ink,
        onTap: content.onYes,
      ),
      if (content.onLater case final VoidCallback later) ...<Widget>[
        const SizedBox(width: 16),
        SimplifiedReminderRoundAnswer(
          label: context.tr('simplified_mode.remind_later'),
          icon: ScheduleIcons.clock,
          fill: SimplifiedColors.surface.withValues(alpha: .24),
          ink: SimplifiedColors.surface,
          onTap: later,
        ),
      ],
    ],
  );
}
