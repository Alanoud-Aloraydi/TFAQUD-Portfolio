import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
        icon: AppIcons.check,
        fill: SimplifiedStyle.accent,
        ink: SimplifiedStyle.ink,
        onTap: content.onYes,
      ),
      if (content.onLater case final VoidCallback later) ...<Widget>[
        const SizedBox(width: 16),
        SimplifiedReminderRoundAnswer(
          label: context.tr('simplified_mode.remind_later'),
          icon: AppIcons.clock,
          fill: SimplifiedStyle.surface.withValues(alpha: .24),
          ink: SimplifiedStyle.surface,
          onTap: later,
        ),
      ],
    ],
  );
}
