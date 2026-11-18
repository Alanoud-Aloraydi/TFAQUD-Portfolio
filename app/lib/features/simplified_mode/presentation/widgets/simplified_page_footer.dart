import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The action pinned at the bottom of a sub-screen.
class SimplifiedPageFooter extends StatelessWidget {
  const SimplifiedPageFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        12,
        SimplifiedStyle.page,
        24,
      ),
      child: child,
    );
  }
}
