// Each circle page has its own skeleton (design system Skeleton), drawn in
// the shape of the page it stands for. These pages already have their
// header and side padding around the body, so the skeletons add neither.
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:app/features/circles/presentation/widgets/previous_notifications_list.dart';
import 'package:app/features/circles/presentation/widgets/request_card_skeleton.dart';
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
