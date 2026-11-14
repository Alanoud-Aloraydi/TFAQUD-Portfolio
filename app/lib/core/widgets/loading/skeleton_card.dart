import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:flutter/material.dart';

/// A placeholder of a content card: a tile, two lines and a detail line, on
/// the same white card as the real one.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppSurfaces.card(),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SkeletonBox(width: 40, height: 40, radius: AppRadius.s),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: SkeletonBox(height: 16),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: SkeletonBox(height: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            FractionallySizedBox(
              widthFactor: 0.5,
              child: SkeletonBox(height: 12),
            ),
          ],
        ),
      ),
    );
  }
}
