import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_form_group.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:easy_localization/easy_localization.dart';
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

class ChipsSkeleton extends StatelessWidget {
  const ChipsSkeleton({super.key, required this.widths});

  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final double width in widths)
          SkeletonBox(width: width, height: 36, radius: AppRadius.capsule),
      ],
    );
  }
}

/// «أكمل الآن» inside the yellow box, which opens the edit page.
class MedicalFileFillButton extends StatelessWidget {
  const MedicalFileFillButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppSemanticColors.textPrimary,
      foregroundColor: AppSemanticColors.surfaceContent,
    ),
    icon: const Icon(ActionIcons.pencil, size: AppSizes.iconSmall),
    label: Text(context.tr('medical_alert.fill')),
  );
}
