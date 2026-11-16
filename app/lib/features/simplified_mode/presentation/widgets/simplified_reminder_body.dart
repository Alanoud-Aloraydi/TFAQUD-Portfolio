import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_answers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_hero.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_words.dart';
import 'package:flutter/material.dart';

/// The reminder itself: the picture first and as big as the screen
/// allows, the words under it, the answers at the bottom.
class SimplifiedReminderBody extends StatelessWidget {
  const SimplifiedReminderBody({super.key, required this.content});

  final SimplifiedReminderContent content;

  /// What the words and the answers need under the picture.
  static const double _rest = 440;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // The picture takes what is left, never smaller than a medicine's
      // box reads at, never so tall the answers leave the screen.
      final double hero = (box.maxHeight - _rest).clamp(180.0, 340.0);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: <Widget>[
                  SimplifiedReminderHero(
                    height: hero,
                    child: content.hero(hero),
                  ),
                  const SizedBox(height: 24),
                  SimplifiedReminderWords(content: content),
                  const Spacer(),
                  const SizedBox(height: 24),
                  SimplifiedReminderAnswers(content: content),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
