import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// Fades from one state of a page to the next (loading, content, error), so
/// content comes in smoothly instead of popping in. [stateKey] names the
/// state; a change of key starts the fade. With Reduce Motion on, the change
/// is instant.
class ContentSwitcher extends StatelessWidget {
  const ContentSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
  });

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: still ? Duration.zero : AppMotion.contentEnter,
      reverseDuration: still ? Duration.zero : AppMotion.contentExit,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeIn,
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey<Object>(stateKey), child: child),
    );
  }
}
