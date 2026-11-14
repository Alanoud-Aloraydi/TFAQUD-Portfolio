import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:app/core/widgets/overlays/glass_menu_row.dart';
import 'package:flutter/material.dart';

/// The rows at their final size; the glass around them clips them while it
/// grows.
class GlassMenuRows extends StatelessWidget {
  const GlassMenuRows({
    super.key,
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
                    child: Divider(
                      height: AppSizes.divider,
                      color: AppEffects.subtleEdge,
                    ),
                  ),
                for (final GlassMenuEntry entry in sections[s])
                  GlassMenuRow(entry: entry, height: rowHeight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
