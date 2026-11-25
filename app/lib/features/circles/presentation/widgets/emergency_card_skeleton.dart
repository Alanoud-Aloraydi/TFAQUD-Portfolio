import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:easy_localization/easy_localization.dart';
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

class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({super.key, required this.valueWidth, this.lines = 1});

  final double valueWidth;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SkeletonLine(widthFactor: 0.3, height: 12),
          for (int i = 0; i < lines; i++) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(widthFactor: valueWidth, height: 16),
          ],
        ],
      ),
    );
  }
}

/// The card could not be read: why, and a button that reads it again.
class EmergencyCardFailure extends StatelessWidget {
  const EmergencyCardFailure({
    super.key,
    required this.messageKey,
    required this.onRetry,
  });

  final String? messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.tr(messageKey ?? 'error.unknown'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.tr('auth.retry')),
          ),
        ],
      ),
    );
  }
}
