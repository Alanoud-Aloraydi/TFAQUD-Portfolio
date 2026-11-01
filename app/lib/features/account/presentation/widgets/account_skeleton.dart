import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';

/// The account page while it loads (design system Skeleton): the card with
/// the round initial and the name, «بياناتي» with its three rows, the note,
/// and the card of the two account actions. The page already has its header
/// and side padding around the body.
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonSurface(
          child: Row(
            children: <Widget>[
              SkeletonCircle(size: 48),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLine(widthFactor: 0.5, height: 20)),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.25, height: 16),
        SizedBox(height: AppSpacing.md),
        SkeletonDetailsCard(rows: 3),
        SizedBox(height: AppSpacing.xl),
        SkeletonLine(widthFactor: 0.8, height: 12),
        SizedBox(height: AppSpacing.md),
        SkeletonDetailsCard(rows: 2),
      ],
    );
  }
}
