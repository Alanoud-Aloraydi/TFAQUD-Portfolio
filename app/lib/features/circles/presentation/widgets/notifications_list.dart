import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:flutter/material.dart';

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
    return RefreshIndicator(
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
