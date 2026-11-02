import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/material.dart';

/// Shows a floating glass sheet, as iOS 26 shows a sheet: it rises from the
/// bottom, `space-2` in from the screen edges, with large concentric corners
/// (`radius-xl`), a grab handle and a light dim behind it. With Reduce
/// Transparency or Increase Contrast the glass turns into the opaque
/// surface ([GlassSurface] decides).
///
/// [title] is centered under the handle (`headline`); [message] is an
/// optional line under it. The [builder] gives the rest of the sheet.
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
    // The glass draws its own handle; the theme's handle would add a second
    // one above the sheet.
    showDragHandle: false,
    backgroundColor: AppSemanticColors.transparent,
    elevation: 0,
    barrierColor: AppSemanticColors.sheetScrim,
    builder: (BuildContext sheetContext) => _GlassSheet(
      title: title,
      message: message,
      child: builder(sheetContext),
    ),
  );
}

class _GlassSheet extends StatelessWidget {
  const _GlassSheet({required this.title, this.message, required this.child});

  final String title;
  final String? message;
  final Widget child;

  static const double _handleWidth = 36;
  static const double _handleHeight = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm + keyboard,
      ),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: _handleWidth,
                    height: _handleHeight,
                    decoration: ShapeDecoration(
                      color: AppSemanticColors.textPrimary.withValues(
                        alpha: 0.25,
                      ),
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
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
