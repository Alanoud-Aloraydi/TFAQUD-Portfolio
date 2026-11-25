import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_card.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The medical file while it loads: the card of six details, the contacts
/// title, two contacts, and the add button.
class MedicalFileSkeleton extends StatelessWidget {
  const MedicalFileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonDetailsCard(rows: 6),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.4, height: 20),
        SizedBox(height: AppSpacing.md),
        ContactSkeleton(),
        SizedBox(height: AppSpacing.md),
        ContactSkeleton(),
        SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SkeletonBox(
            width: 140,
            height: AppSizes.touch,
            radius: AppRadius.capsule,
          ),
        ),
      ],
    );
  }
}

class ContactSkeleton extends StatelessWidget {
  const ContactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Row(
        children: <Widget>[
          SkeletonCircle(size: 40),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonLine(widthFactor: 0.45, height: 16),
                SizedBox(height: AppSpacing.sm),
                SkeletonLine(widthFactor: 0.35, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 20, height: 20, radius: AppRadius.xs),
        ],
      ),
    );
  }
}

/// What the medical file shows when it could not be loaded: why, and a
/// button that asks for it again.
class MedicalFileFailure extends StatelessWidget {
  const MedicalFileFailure({
    super.key,
    required this.messageKey,
    required this.onRetry,
  });

  final String? messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.tr(messageKey ?? 'error.unknown'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
      ],
    ),
  );
}
