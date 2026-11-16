import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

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
        color: SimplifiedStyle.muted,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SimplifiedStyle.attentionEdge, width: 5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}
