import 'package:app/core/navigation/fading_branch.dart';
import 'package:flutter/material.dart';

/// Holds the four tabs and fades between them (design system Motion): the
/// tab being left fades out quickly, then the tab being opened fades in, so
/// the change is smooth instead of a sudden swap. Every tab stays alive, so it
/// keeps its scroll position; once a tab has faded out it goes offstage, as
/// in an IndexedStack. With Reduce Motion on, the change is instant.
class FadingBranches extends StatelessWidget {
  const FadingBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (int i = 0; i < children.length; i++)
          FadingBranch(
            active: i == currentIndex,
            still: still,
            child: children[i],
          ),
      ],
    );
  }
}
