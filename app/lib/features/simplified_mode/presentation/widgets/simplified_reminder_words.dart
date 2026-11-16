import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// What the reminder asks, read as one sentence: «حان وقت»، the task's
/// name, its line, who comes along, and its short notes.
class SimplifiedReminderWords extends StatelessWidget {
  const SimplifiedReminderWords({super.key, required this.content});

  final SimplifiedReminderContent content;

  static const Color _ink = SimplifiedStyle.surface;

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
