import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_box.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/core/widgets/loading/skeleton_surface.dart';
import 'package:app/features/circles/presentation/widgets/section_skeleton.dart';
import 'package:flutter/material.dart';

/// The emergency card while it loads: the dark name card (drawn as one
/// shape, since its real color is ink) and the details card with its
/// sections.
class EmergencyCardSkeleton extends StatelessWidget {
  const EmergencyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonBox(height: 132, radius: AppRadius.l),
        SizedBox(height: AppSpacing.lg),
        SkeletonSurface(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: <Widget>[
              SectionSkeleton(valueWidth: 0.3),
              Divider(height: AppSizes.divider),
              SectionSkeleton(valueWidth: 0.7),
              Divider(height: AppSizes.divider),
              SectionSkeleton(valueWidth: 0.55, lines: 2),
            ],
          ),
        ),
      ],
    );
  }
}
