import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
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

/// A card of rows, each a short label at the start and a value at the end,
/// as the medical file and the account show their details.
class SkeletonDetailsCard extends StatelessWidget {
  const SkeletonDetailsCard({super.key, required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: AppSizes.divider,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  const SkeletonBox(width: 72, height: 16),
                  const Spacer(),
                  SkeletonBox(width: i.isEven ? 96 : 64, height: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
