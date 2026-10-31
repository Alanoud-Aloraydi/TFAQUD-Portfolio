import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/glass.dart';
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
/// as iOS 26 pull-down menus do (design system TopBar, circle switcher): the
/// glass swells from the control's size and shape into the menu, its rows
/// coming into focus as it opens, and folds back into the control when it
/// closes. [anchorContext] is the control's context. The menu lines up with
/// the control's top and stays 16 from the screen edges.
///
/// Rows come in [sections], with a separator between sections. Returns the
/// tapped row's value, or null when the person taps outside the menu.
Future<T?> showGlassMenu<T>({
  required BuildContext anchorContext,
  required List<List<GlassMenuItem<T>>> sections,
  required String semanticLabel,
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
    _GlassMenuRoute(
      anchor: anchor,
      semanticLabel: semanticLabel,
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

/// A row as the menu draws it, without its type.
class GlassMenuEntry {
  const GlassMenuEntry({
    required this.value,
    required this.label,
    this.icon,
    this.selected = false,
  });

  final Object? value;
  final String label;
  final IconData? icon;
  final bool selected;
}

class _GlassMenuRoute extends PopupRoute<Object?> {
  _GlassMenuRoute({
    required this.anchor,
    required this.sections,
    required this.semanticLabel,
  });

  final Rect anchor;
  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => semanticLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return GlassMenu(
      anchor: anchor,
      sections: sections,
      semanticLabel: semanticLabel,
      animation: animation,
    );
  }
}

/// The open menu (see [showGlassMenu]). Public so tests can find its rows.
class GlassMenu extends StatelessWidget {
  const GlassMenu({
    super.key,
    required this.anchor,
    required this.sections,
    required this.semanticLabel,
    required this.animation,
  });

  final Rect anchor;
  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;
  final Animation<double> animation;

  /// The glass opens with a small overshoot, like a spring, and closes
  /// straight back.
  static const Curve _open = Cubic(0.25, 1.15, 0.4, 1);
  static const Curve _close = Curves.easeInCubic;

  static const double _minWidth = 248;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double room = constraints.maxWidth - 2 * AppSpacing.lg;
        final double width = math.min(
          math.max(anchor.width + 96, _minWidth),
          room,
        );
        final double left = (anchor.center.dx - width / 2).clamp(
          AppSpacing.lg,
          constraints.maxWidth - AppSpacing.lg - width,
        );
        // The point of the menu that sits on the control: it grows from
        // there.
        final Alignment origin = Alignment(
          ((anchor.center.dx - left) / width) * 2 - 1,
          -1,
        );
        final double startScale = (anchor.width / width).clamp(0.3, 1.0);
        final CurvedAnimation curve = CurvedAnimation(
          parent: animation,
          curve: _open,
          reverseCurve: _close,
        );
        return Stack(
          children: <Widget>[
            Positioned(
              top: anchor.top,
              left: left,
              width: width,
              child: AnimatedBuilder(
                animation: curve,
                builder: (BuildContext context, Widget? child) {
                  final double t = curve.value;
                  final double fade = Curves.easeOut.transform(
                    (animation.value * 2).clamp(0.0, 1.0),
                  );
                  if (still) {
                    return Opacity(opacity: animation.value, child: child);
                  }
                  return Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      alignment: origin,
                      scale: lerpDouble(startScale, 1, t)!,
                      child: child,
                    ),
                  );
                },
                child: _MenuPanel(
                  sections: sections,
                  semanticLabel: semanticLabel,
                  animation: animation,
                  still: still,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.sections,
    required this.semanticLabel,
    required this.animation,
    required this.still,
  });

  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;
  final Animation<double> animation;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final Widget rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int s = 0; s < sections.length; s++) ...<Widget>[
          if (s > 0)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Divider(height: 1, color: Color(0x1F202734)),
            ),
          for (final GlassMenuEntry entry in sections[s]) _MenuRow(entry: entry),
        ],
      ],
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: GlassSurface(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.l)),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            // The rows come into focus as the glass opens.
            child: still
                ? rows
                : AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double blur = (1 - animation.value) * 10;
                      if (blur < 0.1) return child!;
                      return ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: child,
                      );
                    },
                    child: rows,
                  ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.entry});

  final GlassMenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final IconData? icon = entry.selected ? Icons.check : entry.icon;
    return Semantics(
      button: true,
      selected: entry.selected,
      child: Padding(
        // 8 inside the 28 panel: the pressed highlight is radius 20, so the
        // two corners are concentric.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(entry.value),
          customBorder: AppRadius.shape(AppRadius.m),
          highlightColor: const Color(0x14202734),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch + 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSizes.icon,
                    child: icon == null
                        ? null
                        : Icon(icon, size: AppSizes.iconSmall, color: AppColors.ink),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: entry.selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
