import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A small grey label («مع الأكل»), or a tappable choice when [onTap] is
/// set.
class SimplifiedChip extends StatelessWidget {
  const SimplifiedChip(
    this.text, {
    super.key,
    this.selected = false,
    this.onDark = false,
    this.onTap,
  });

  final String text;
  final bool selected;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool choice = onTap != null;
    // A choice says whether it is the chosen one; a plain label says nothing
    // beyond its text.
    final Color fill = onDark
        ? SimplifiedStyle.surface.withValues(alpha: .14)
        : selected
        ? SimplifiedStyle.accentTint
        : choice
        ? SimplifiedStyle.clear
        : SimplifiedStyle.chip;
    // A choice is at least [SimplifiedStyle.touch] high, and grows with a
    // large text.
    final Widget body = Container(
      constraints: choice
          ? const BoxConstraints(minHeight: SimplifiedStyle.touch)
          : null,
      alignment: choice ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(26),
        border: choice
            ? Border.all(color: SimplifiedStyle.control, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            text,
            style: SimplifiedStyle.label(
              SimplifiedStyle.caption,
              color: onDark ? SimplifiedStyle.surface : SimplifiedStyle.ink,
            ),
          ),
          if (selected) ...<Widget>[
            const SizedBox(width: 6),
            const ExcludeSemantics(child: Icon(AppIcons.check, size: 18)),
          ],
        ],
      ),
    );
    if (!choice) return body;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: body,
      ),
    );
  }
}
