import 'dart:math' as math;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:flutter/material.dart';

/// Positions the glass menu above the current route.
class GlassMenuRoute extends PopupRoute<Object?> {
  GlassMenuRoute({
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
  Duration get transitionDuration => AppMotion.menuEnter;

  @override
  Duration get reverseTransitionDuration => AppMotion.menuExit;

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

/// Shows a floating glass sheet, as iOS 26 shows a sheet: it rises from the
/// bottom, `space-2` in from the screen edges, with the corners of the
/// app's cards and menus (`radius-l`), a grab handle and a light dim behind
/// it. However tall its content, its top stays under the page's top bar
/// ([glassSheetTopGap]), so the page it opened over still shows above it.
/// With Reduce Transparency or Increase Contrast the glass turns into the
/// opaque surface ([GlassSurface] decides).
///
/// [title] is centered under the handle (`headline`); [message] is an
/// optional line under it. The [builder] gives the rest of the sheet, which
/// scrolls under them. Dragging the handle or the title down closes it.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required String title,
  String? message,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Above the tab bar: a sheet covers the whole screen, as on iOS.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    // Under the top bar, however tall its content: it scrolls instead.
    constraints: BoxConstraints(
      maxHeight: glassSheetMaxHeight(MediaQuery.of(context)),
    ),
    // The glass draws its own handle; the theme's handle would add a second
    // one above the sheet.
    showDragHandle: false,
    backgroundColor: AppSemanticColors.transparent,
    elevation: 0,
    barrierColor: AppSemanticColors.sheetScrim,
    builder: (BuildContext sheetContext) => GlassSheetFrame(
      title: title,
      message: message,
      child: builder(sheetContext),
    ),
  );
}

/// The glass panel of a sheet: the header on top and, under it, [child] in a
/// scroll view.
class GlassSheetFrame extends StatelessWidget {
  const GlassSheetFrame({
    super.key,
    required this.title,
    this.message,
    required this.child,
  });

  final String title;
  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm + glassSheetBottomInset(MediaQuery.of(context)),
      ),
      child: GlassSurface(
        // On top of everything: the tab bar does not show through.
        dense: true,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The handle and the title stay put above what scrolls, so a
              // drag that starts on them pulls the whole sheet down and
              // closes it, as a sheet's grabber does on iOS.
              GlassSheetHeader(title: title, message: message),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The handle, the title and the optional message at the top of a glass
/// sheet.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({super.key, required this.title, this.message});

  final String title;
  final String? message;

  static const double _handleWidth = 36;
  static const double _handleHeight = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: _handleWidth,
              height: _handleHeight,
              decoration: ShapeDecoration(
                color: AppSemanticColors.textPrimary.withValues(alpha: 0.25),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: AppSemanticColors.textSupporting,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The room a glass sheet leaves above itself, under the status bar: the
/// height of the page's top bar, so a tall sheet starts below it.
const double glassSheetTopGap = 64;

/// The tallest a glass sheet grows on a screen of [media]: from the bottom
/// up to [glassSheetTopGap] under the status bar.
double glassSheetMaxHeight(MediaQueryData media) =>
    media.size.height - media.viewPadding.top - glassSheetTopGap;

/// How far the glass sheet floats above the screen's bottom edge, before its
/// own gap: over the keyboard while it is open, otherwise over the iPhone's
/// home indicator or Android's navigation bar. `useSafeArea` keeps a sheet
/// clear of the top and the sides only, and from Android 15 the app draws
/// under the navigation bar, whose buttons would cover the last row.
double glassSheetBottomInset(MediaQueryData media) =>
    math.max(media.viewInsets.bottom, media.viewPadding.bottom);
