import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:flutter/material.dart';

class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonSurface(
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonCircle(size: 40),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SkeletonLine(widthFactor: 0.5, height: 16),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonLine(widthFactor: 0.9, height: 12),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonLine(widthFactor: 0.65, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SkeletonBox(width: 64, height: 24, radius: AppRadius.s),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppRadius.capsule,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppRadius.capsule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «الحالية»: the invitations and requests that wait for an answer.
class NotificationsList extends StatelessWidget {
  const NotificationsList({
    super.key,
    required this.cubit,
    required this.state,
  });

  final InboxCubit cubit;
  final InboxState state;

  @override
  Widget build(BuildContext context) {
    return LogoRefresh(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          if (state.inbox.needsReply == 0)
            const NotificationsEmpty(messageKey: 'circles.inbox_empty')
          else
            PendingInvitesSection(cubit: cubit, state: state),
        ],
      ),
    );
  }
}
