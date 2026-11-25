import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/inbox_reply_buttons.dart';
import 'package:app/features/circles/presentation/widgets/pending_invite_cards.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The invitations and requests that need a reply, on the notifications
/// page and the start-of-onboarding page (a brand-new person may have one
/// waiting). There an accepted invitation calls [onAccepted], which leaves
/// for the circle. The card a tapped push is about is outlined.
class PendingInvitesSection extends StatelessWidget {
  const PendingInvitesSection({
    super.key,
    required this.cubit,
    required this.state,
    this.maxItems,
    this.onAccepted,
  });

  final InboxCubit cubit;
  final InboxState state;

  /// Caps how many cards show before a "عرض الكل" link takes over, for a
  /// page that only wants a short teaser (the start-of-onboarding page).
  /// `null` (the notifications page) shows every one of them.
  final int? maxItems;

  /// Called once an invitation is accepted. `null` (the notifications page)
  /// stays on the page.
  final VoidCallback? onAccepted;

  @override
  Widget build(BuildContext context) {
    if (state.inbox.needsReply == 0) return const SizedBox.shrink();
    final List<Widget> cards = pendingInviteCards(
      context,
      cubit: cubit,
      state: state,
      onAccepted: onAccepted,
    );
    final int? cap = maxItems;
    final bool truncated = cap != null && cards.length > cap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NeedsReplyHeader(count: state.inbox.needsReply),
        ...(truncated ? cards.take(cap) : cards).map(inboxFocusMark),
        if (truncated)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.push(Routes.notifications),
              child: Text(context.tr('circles.show_all_requests')),
            ),
          ),
      ],
    );
  }
}

/// How many invitations and requests wait for a reply, over their cards.
class NeedsReplyHeader extends StatelessWidget {
  const NeedsReplyHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.inset,
        bottom: AppSpacing.labelGap,
      ),
      child: Text(
        context.tr('circles.needs_reply', args: <String>['$count']),
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: context.tokens.textSecondary),
      ),
    );
  }
}
