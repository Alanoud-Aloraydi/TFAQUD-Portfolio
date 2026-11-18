import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/notifications_tab.dart';
import 'package:app/features/circles/presentation/widgets/notifications_failure.dart';
import 'package:app/features/circles/presentation/widgets/notifications_list.dart';
import 'package:app/features/circles/presentation/widgets/notifications_skeleton.dart';
import 'package:app/features/circles/presentation/widgets/previous_notifications_list.dart';
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
