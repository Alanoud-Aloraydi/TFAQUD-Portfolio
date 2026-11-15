import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/presentation/widgets/chips_skeleton.dart';
import 'package:flutter/material.dart';

/// The medical file's edit page while it loads: the name fields and the
/// pickers as form rows, then the choices as rows of chips.
class MedicalFileEditSkeleton extends StatelessWidget {
  const MedicalFileEditSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.md),
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.md),
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.md),
        SkeletonFormGroup(rows: 1, header: false),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.3, height: 16),
        SizedBox(height: AppSpacing.sm),
        ChipsSkeleton(widths: <double>[56, 56, 56, 56, 64, 64]),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.35, height: 16),
        SizedBox(height: AppSpacing.sm),
        ChipsSkeleton(widths: <double>[96, 72, 112, 88, 64]),
      ],
    );
  }
}
