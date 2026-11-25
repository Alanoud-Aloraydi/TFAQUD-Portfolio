import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_sheet_frame.dart';
import 'package:app/core/widgets/overlays/glass_sheet_header.dart';
import 'package:flutter/material.dart';

export 'package:app/core/widgets/overlays/glass_sheet_header.dart';

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
