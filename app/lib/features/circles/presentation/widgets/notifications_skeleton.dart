import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/presentation/widgets/request_card_skeleton.dart';
import 'package:flutter/material.dart';

// Each circle page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for. These pages already have their
// header and side padding around the body, so the skeletons add neither.

/// The notifications while they load: the section title, then request
/// cards with the round avatar, the name, two lines, the pill, and the two
/// reply buttons side by side.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonLine(widthFactor: 0.4, height: 16),
        SizedBox(height: AppSpacing.md),
        RequestCardSkeleton(),
        SizedBox(height: AppSpacing.md),
        RequestCardSkeleton(),
      ],
    );
  }
}
