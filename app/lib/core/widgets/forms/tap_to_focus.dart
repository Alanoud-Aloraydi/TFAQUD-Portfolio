import 'package:flutter/widgets.dart';

/// Makes all of a field's row a target: a tap anywhere on it, the label
/// too, puts the cursor in its text field. [builder] gets the focus node to
/// give that field: [focusNode] when the caller has one, else its own.
class TapToFocus extends StatefulWidget {
  const TapToFocus({super.key, this.focusNode, required this.builder});

  final FocusNode? focusNode;
  final Widget Function(FocusNode node) builder;

  @override
  State<TapToFocus> createState() => _TapToFocusState();
}

class _TapToFocusState extends State<TapToFocus> {
  FocusNode? _own;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _node.requestFocus,
    // The field's own taps (the cursor, selecting) stay the field's.
    excludeFromSemantics: true,
    child: widget.builder(_node),
  );
}
