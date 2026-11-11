import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/previous_requests.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:app/features/circles/presentation/widgets/previous_requests_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The notifications: current requests first, then the previous ones.
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
    final List<SentCircleRequest> previous = PreviousRequests.of(state.inbox);
    final bool hasCurrent = state.inbox.needsReply > 0;
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          if (!hasCurrent && previous.isEmpty) const NotificationsEmpty(),
          if (hasCurrent) PendingInvitesSection(cubit: cubit, state: state),
          if (!hasCurrent && previous.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.inset,
              ),
              child: Text(
                context.tr('circles.none_current'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            ),
          PreviousRequestsSection(requests: previous),
        ],
      ),
    );
  }
}
