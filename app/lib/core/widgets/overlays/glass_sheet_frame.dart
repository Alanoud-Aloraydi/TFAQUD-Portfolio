import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_sheet_header.dart';
import 'package:app/core/widgets/overlays/glass_sheet_metrics.dart';
import 'package:flutter/material.dart';

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
