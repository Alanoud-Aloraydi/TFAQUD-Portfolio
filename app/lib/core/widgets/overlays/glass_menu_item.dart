import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One row of a [GlassMenu].
class GlassMenuItem<T> {
  const GlassMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.selected = false,
  });

  /// What [showGlassMenu] returns when this row is tapped.
  final T value;
  final String label;

  /// Shown at the start of the row. A selected row shows a check mark
  /// instead.
  final IconData? icon;

  /// The current choice: a check mark and a heavier weight.
  final bool selected;
}

/// Opens a Liquid Glass menu that grows out of the control that opened it,
/// as iOS 26 pull-down menus do (design system TopBar, circle switcher).
///
/// The glass itself changes shape: it starts exactly as the control (same
/// place, size and capsule corners) and swells into the menu with a spring,
/// in about a third of a second. The control's [anchorContent] blurs away as
/// the rows come into focus. Closing runs the other way, back into the
/// control. The control should hide itself while the menu is open, so there
/// is only one piece of glass.
///
/// Rows come in [sections], with a separator between sections. Returns the
/// tapped row's value, or null when the person taps outside the menu.
Future<T?> showGlassMenu<T>({
  required BuildContext anchorContext,
  required List<List<GlassMenuItem<T>>> sections,
  required String semanticLabel,
  Widget? anchorContent,
}) async {
  final NavigatorState navigator = Navigator.of(anchorContext);
  final RenderBox anchorBox = anchorContext.findRenderObject()! as RenderBox;
  final RenderBox overlayBox =
      navigator.overlay!.context.findRenderObject()! as RenderBox;
  final Rect anchor =
      anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
      anchorBox.size;
  HapticFeedback.selectionClick();
  final Object? picked = await navigator.push<Object?>(
    GlassMenuRoute(
      anchor: anchor,
      semanticLabel: semanticLabel,
      anchorContent: anchorContent,
      sections: <List<GlassMenuEntry>>[
        for (final List<GlassMenuItem<T>> section in sections)
          <GlassMenuEntry>[
            for (final GlassMenuItem<T> item in section)
              GlassMenuEntry(
                value: item.value,
                label: item.label,
                icon: item.icon,
                selected: item.selected,
              ),
          ],
      ],
    ),
  );
  return picked is T ? picked : null;
}
