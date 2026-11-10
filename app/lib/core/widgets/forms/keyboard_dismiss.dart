import 'package:flutter/widgets.dart';

/// Closes the keyboard when the user touches anywhere outside the text
/// fields, as iOS apps do. A number pad has no return key, so without this
/// the keyboard would stay open.
///
/// Flutter asks [EditableTextTapOutsideIntent] what to do on such a touch;
/// on a phone its default does nothing. This widget wraps the whole app and
/// answers it: the field loses focus and the keyboard goes down. A touch on
/// another text field counts as inside, so moving between fields keeps the
/// keyboard up. Dragging a form also closes it (each form's scroll view
/// uses `ScrollViewKeyboardDismissBehavior.onDrag`).
class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (EditableTextTapOutsideIntent intent) {
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: child,
    );
  }
}
