import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// One answer on a dark screen («نسيتها»): a wide, quiet card with its
/// words in the middle, at least 76 high and taller when a large text
/// wraps. Disabled ([onTap] null) while an answer is being saved.
class SimplifiedDarkChoice extends StatelessWidget {
  const SimplifiedDarkChoice({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(SimplifiedStyle.radius);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: SimplifiedColors.surface.withValues(alpha: .1),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 76,
              minWidth: double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: SimplifiedStyle.head(
                    SimplifiedStyle.headline,
                    color: SimplifiedColors.surface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
