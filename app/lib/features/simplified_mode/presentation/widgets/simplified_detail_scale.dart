import 'package:app/features/simplified_mode/presentation/widgets/apply_text_scale.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:flutter/material.dart';

/// A page or part the simplified mode takes from the detailed mode (the
/// medical file's edit page, the emergency card, the contact form) at the
/// simplified mode's size, on top of [SimplifiedTextScale].
///
/// The mode puts nothing below [SimplifiedStyle.caption], so the smallest
/// type of the borrowed page is what is measured: its footnotes reach that
/// floor, and the rest of its type grows in proportion. Measuring the body
/// instead left the footnotes — the medicine lines of the card, the hints
/// under a field — under the floor, which is the type this mode exists for.
class SimplifiedDetailScale extends StatelessWidget {
  const SimplifiedDetailScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double smallest =
        Theme.of(context).textTheme.bodySmall?.fontSize ??
        SimplifiedStyle.caption;
    return applyTextScale(context, SimplifiedStyle.caption / smallest, child);
  }
}
