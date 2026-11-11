import 'package:flutter/widgets.dart';

/// Tells [builder] whether a finger is down anywhere on the child. It listens
/// to raw pointers, so the child's own taps still win the gesture arena.
class PressStateListener extends StatefulWidget {
  const PressStateListener({super.key, required this.builder});

  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<PressStateListener> createState() => _PressStateListenerState();
}

class _PressStateListenerState extends State<PressStateListener> {
  int _fingersDown = 0;

  void _change(int delta) =>
      setState(() => _fingersDown = (_fingersDown + delta).clamp(0, 99));

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _change(1),
      onPointerUp: (_) => _change(-1),
      onPointerCancel: (_) => _change(-1),
      child: widget.builder(context, _fingersDown > 0),
    );
  }
}
