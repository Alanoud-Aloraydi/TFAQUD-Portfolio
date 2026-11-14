import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_surface.dart';
import 'package:flutter/material.dart';

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
