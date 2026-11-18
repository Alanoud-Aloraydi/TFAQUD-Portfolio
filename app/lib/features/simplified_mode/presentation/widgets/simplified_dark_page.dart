import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// A full dark screen of this mode, in one colour: [child] at the top,
/// [actions] at the bottom when there is room, and the whole of it
/// scrolling when the text is large, so nothing is cut off.
class SimplifiedDarkPage extends StatelessWidget {
  const SimplifiedDarkPage({
    super.key,
    required this.child,
    required this.actions,
  });

  final Widget child;
  final Widget actions;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(20, 32, 20, 40);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SimplifiedColors.reminderGround,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: _padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: box.maxHeight - _padding.vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                child,
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
