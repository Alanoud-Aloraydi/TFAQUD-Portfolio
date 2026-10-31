import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
    _GlassMenuRoute(
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

/// The spring of iOS glass: it reaches about 90% within the first eighth of
/// a second, passes its size by about 4% and settles, as in the system menus.
/// (Stiffness 300, damping ratio 0.72, over 420 ms.)
class _GlassSpring extends Curve {
  const _GlassSpring();

  static final SpringSimulation _spring = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.72),
    0,
    1,
    0,
  );

  static const double _seconds = 0.42;

  @override
  double transformInternal(double t) => _spring.x(t * _seconds);
}

class _GlassMenuRoute extends PopupRoute<Object?> {
  _GlassMenuRoute({
    required this.anchor,
    required this.sections,
    required this.semanticLabel,
    this.anchorContent,
  });

  final Rect anchor;
  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;
  final Widget? anchorContent;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => semanticLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

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
      anchorContent: anchorContent,
    );
  }
}

/// The open menu (see [showGlassMenu]). Public so tests can find its rows.
class GlassMenu extends StatefulWidget {
  const GlassMenu({
    super.key,
    required this.anchor,
    required this.sections,
    required this.semanticLabel,
    required this.animation,
    this.anchorContent,
  });

  final Rect anchor;
  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;
  final Animation<double> animation;
  final Widget? anchorContent;

  static const double _minWidth = 248;
  static const double _separator = 1 + 2 * AppSpacing.xs;

  /// Height of one row: at least 48, more with larger text.
  static double rowHeight(BuildContext context) => math.max(
    AppSizes.touch + AppSpacing.xs,
    MediaQuery.textScalerOf(context).scale(26) + 2 * AppSpacing.sm,
  );

  @override
  State<GlassMenu> createState() => _GlassMenuState();

  static Widget _blurred(double sigma, Widget child) {
    if (sigma < 0.2) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}

class _GlassMenuState extends State<GlassMenu> {
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: widget.animation,
    curve: const _GlassSpring(),
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect anchor = widget.anchor;
    final List<List<GlassMenuEntry>> sections = widget.sections;
    final Animation<double> animation = widget.animation;
    final Widget? anchorContent = widget.anchorContent;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final bool highContrast = MediaQuery.highContrastOf(context);
    final double row = GlassMenu.rowHeight(context);
    final int rows = sections.fold(0, (int n, List<GlassMenuEntry> s) => n + s.length);
    final double edge = highContrast ? 3 : 1;
    final double height =
        2 * AppSpacing.sm +
        rows * row +
        (sections.length - 1) * GlassMenu._separator +
        edge;
    final CurvedAnimation curve = _curve;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double room = constraints.maxWidth - 2 * AppSpacing.lg;
        final double width = math.min(
          math.max(anchor.width + 96, GlassMenu._minWidth),
          room,
        );
        final double left = (anchor.center.dx - width / 2).clamp(
          AppSpacing.lg,
          constraints.maxWidth - AppSpacing.lg - width,
        );
        final Rect target = Rect.fromLTWH(left, anchor.top, width, height);
        final Widget rowsColumn = _MenuRows(
          sections: sections,
          rowHeight: row,
          width: width,
          height: height - edge,
        );

        return AnimatedBuilder(
          animation: curve,
          builder: (BuildContext context, Widget? _) {
            final double t = still ? 1 : curve.value;
            // The glass: from the control's rectangle to the menu's, with
            // the spring's small overshoot.
            final Rect rect = Rect.lerp(anchor, target, t)!;
            final double radius = lerpDouble(
              anchor.shortestSide / 2,
              AppRadius.l,
              t.clamp(0.0, 1.0),
            )!.clamp(0.0, rect.shortestSide / 2);
            // The rows come into focus fast; the control's own content
            // blurs away even faster.
            final double rowsIn = still
                ? animation.value
                : (t * 2.2).clamp(0.0, 1.0);
            final double blur = still ? 0 : (1 - rowsIn) * 8;
            final double anchorOut = still ? 0 : (1 - t * 4).clamp(0.0, 1.0);
            final double scale = (rect.width / width).clamp(0.5, 1.06);

            return Stack(
              children: <Widget>[
                Positioned.fromRect(
                  rect: rect,
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: widget.semanticLabel,
                    child: GlassSurface(
                      borderRadius: BorderRadius.all(Radius.circular(radius)),
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            if (anchorContent != null && anchorOut > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: anchorOut,
                                    child: GlassMenu._blurred(
                                      (1 - anchorOut) * 6,
                                      Center(child: anchorContent),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 0,
                              left: (rect.width - width) / 2,
                              width: width,
                              height: height - edge,
                              child: Opacity(
                                opacity: rowsIn,
                                child: Transform.scale(
                                  alignment: Alignment.topCenter,
                                  scale: scale,
                                  child: GlassMenu._blurred(blur, rowsColumn),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

/// The rows at their final size; the glass around them clips them while it
/// grows.
class _MenuRows extends StatelessWidget {
  const _MenuRows({
    required this.sections,
    required this.rowHeight,
    required this.width,
    required this.height,
  });

  final List<List<GlassMenuEntry>> sections;
  final double rowHeight;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      minWidth: width,
      maxWidth: width,
      minHeight: height,
      maxHeight: height,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
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
                for (final GlassMenuEntry entry in sections[s])
                  _MenuRow(entry: entry, height: rowHeight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.entry, required this.height});

  final GlassMenuEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final IconData? icon = entry.selected ? Icons.check : entry.icon;
    return Semantics(
      button: true,
      selected: entry.selected,
      child: SizedBox(
        height: height,
        child: Padding(
          // 8 inside the 28 panel: the pressed highlight is radius 20, so the
          // two corners are concentric.
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(entry.value);
            },
            customBorder: AppRadius.shape(AppRadius.m),
            highlightColor: const Color(0x14202734),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
