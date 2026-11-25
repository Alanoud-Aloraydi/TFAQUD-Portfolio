import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_words.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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

/// The reminder's one picture: as wide as the screen, in the honey edge,
/// big enough to know the medicine by its box from across the room.
/// Decorative: the words under it name the task.
class SimplifiedReminderHero extends StatelessWidget {
  const SimplifiedReminderHero({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: SimplifiedColors.muted,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SimplifiedColors.attentionEdge, width: 5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}
