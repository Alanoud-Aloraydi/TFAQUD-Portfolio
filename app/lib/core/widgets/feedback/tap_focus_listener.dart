import 'package:app/app/services/tap_focus.dart';
import 'package:flutter/widgets.dart';

/// Tells [onWaiting] the item of the notification just tapped while it
/// still waits to be brought into view ([TapFocus.waiting]): at the tap,
/// and once right after this is first built. A box that folds opens for an
/// item of its own with it: folded, it builds none of its cards, so none
/// could claim the tap.
class TapFocusListener extends StatefulWidget {
  const TapFocusListener({
    super.key,
    required this.onWaiting,
    required this.child,
  });

  final ValueChanged<String> onWaiting;
  final Widget child;

  @override
  State<TapFocusListener> createState() => _TapFocusListenerState();
}

class _TapFocusListenerState extends State<TapFocusListener> {
  @override
  void initState() {
    super.initState();
    TapFocus.instance.addListener(_tell);
    // Not during the build that mounts it: right after.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tell());
  }

  @override
  void dispose() {
    TapFocus.instance.removeListener(_tell);
    super.dispose();
  }

  void _tell() {
    final String? waiting = TapFocus.instance.waiting;
    if (mounted && waiting != null) widget.onWaiting(waiting);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
