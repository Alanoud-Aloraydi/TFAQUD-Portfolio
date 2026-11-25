// Each circle page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for. These pages already have their
// header and side padding around the body, so the skeletons add neither.
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/inbox_reply_buttons.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the notifications page holds for its load [state] and the [tab] on
/// show: the skeleton, the retry, or the list of that tab.
class NotificationsContent extends StatelessWidget {
  const NotificationsContent({
    super.key,
    required this.cubit,
    required this.state,
    required this.tab,
  });

  final InboxCubit cubit;
  final InboxState state;
  final NotificationsTab tab;

  @override
  Widget build(BuildContext context) => switch (state.status) {
    InboxStatus.loading => const NotificationsSkeleton(),
    InboxStatus.failure => NotificationsFailure(
      messageKey: state.messageKey,
      onRetry: cubit.load,
    ),
    InboxStatus.ready =>
      tab == NotificationsTab.current
          ? NotificationsList(cubit: cubit, state: state)
          : PreviousNotificationsList(cubit: cubit, state: state),
  };
}

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

/// The first load failed: the reason and a retry button.
class NotificationsFailure extends StatelessWidget {
  const NotificationsFailure({
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

/// «السابقة»: the invitations and requests answered in the last 30 days,
/// newest first, each with how long ago it was answered.
class PreviousNotificationsList extends StatelessWidget {
  const PreviousNotificationsList({
    super.key,
    required this.cubit,
    required this.state,
  });

  final InboxCubit cubit;
  final InboxState state;

  @override
  Widget build(BuildContext context) {
    final List<PreviousNotification> previous = state.inbox.previous;
    return LogoRefresh(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          if (previous.isEmpty)
            const NotificationsEmpty(messageKey: 'circles.previous_empty'),
          ...previous.map(answeredFocusCard),
          if (previous.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                context.tr('circles.previous_kept'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

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
