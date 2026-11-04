import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// Changes an adjacent selection after a deliberate horizontal content swipe.
class SwipeSelectionArea extends StatefulWidget {
  const SwipeSelectionArea({
    super.key,
    required this.child,
    required this.onPrevious,
    required this.onNext,
  });

  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  State<SwipeSelectionArea> createState() => _SwipeSelectionAreaState();
}

class _SwipeSelectionAreaState extends State<SwipeSelectionArea> {
  double _distance = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragStart: (_) => _distance = 0,
    onHorizontalDragUpdate: (details) {
      _distance += details.primaryDelta ?? 0;
    },
    onHorizontalDragEnd: (details) {
      final velocity = details.primaryVelocity ?? 0;
      if (_distance.abs() < AppSizes.touch && velocity.abs() < 300) return;
      final direction = _distance.abs() >= AppSizes.touch
          ? _distance
          : velocity;
      final next = Directionality.of(context) == TextDirection.rtl
          ? direction < 0
          : direction > 0;
      if (next) {
        widget.onNext();
      } else {
        widget.onPrevious();
      }
    },
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.touch * 2),
      child: widget.child,
    ),
  );
}
