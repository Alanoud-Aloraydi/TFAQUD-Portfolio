import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/inbox_cards.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The invitations and requests that need a reply, shared by the
/// notifications page and the start-of-onboarding page: a brand-new person
/// may already have one waiting (someone invited them before they ever
/// opened the app), and answering it here picks their circle directly,
/// skipping the self/other choice below.
class PendingInvitesSection extends StatelessWidget {
  const PendingInvitesSection({
    super.key,
    required this.cubit,
    required this.state,
    this.maxItems,
  });

  final InboxCubit cubit;
  final InboxState state;

  /// Caps how many cards show before a "عرض الكل" link takes over, for a
  /// page that only wants a short teaser (the start-of-onboarding page).
  /// `null` (the notifications page) shows every one of them.
  final int? maxItems;

  Future<void> _open(
    BuildContext context,
    String route,
    ReceivedCircleRequest request,
  ) async {
    await context.push<void>(route, extra: request);
    if (!cubit.isClosed) cubit.load();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    ReceivedCircleRequest request,
  ) async {
    final bool? yes = await showAppAlert<bool>(
      context,
      title: context.tr('circles.cancel_confirm_title'),
      message: context.tr('circles.cancel_confirm_body_patient'),
      actions: <AppAlertAction<bool>>[
        AppAlertAction<bool>(
          label: context.tr('circles.cancel_confirm_no'),
          value: false,
        ),
        AppAlertAction<bool>(
          label: context.tr('circles.cancel_confirm_yes'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (yes == true) await cubit.cancelRequest(request.id);
  }

  @override
  Widget build(BuildContext context) {
    if (state.inbox.needsReply == 0) return const SizedBox.shrink();
    final List<Widget> cards = <Widget>[
      for (final ReceivedInvitation invitation in state.inbox.invitations)
        InvitationCard(
          invitation: invitation,
          busy: state.busyIds.contains(invitation.id),
          onAccept: () =>
              cubit.respondToInvitation(invitation.id, accept: true),
          onDecline: () =>
              cubit.respondToInvitation(invitation.id, accept: false),
        ),
      for (final ReceivedCircleRequest request in state.inbox.received)
        if (request.isAccepted)
          AcceptedRequestCard(
            key: ValueKey(request.id),
            request: request,
            busy: state.busyIds.contains(request.id),
            onContinue: () => _open(context, Routes.completeRequest, request),
            onCancel: () => _confirmCancel(context, request),
          )
        else
          RequestCard(
            key: ValueKey(request.id),
            request: request,
            onView: () => _open(context, Routes.replyRequest, request),
          ),
    ];
    final int? cap = maxItems;
    final bool truncated = cap != null && cards.length > cap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.inset,
            bottom: AppSpacing.labelGap,
          ),
          child: Text(
            context.tr(
              'circles.needs_reply',
              args: <String>['${state.inbox.needsReply}'],
            ),
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: context.tokens.textSecondary),
          ),
        ),
        ...(truncated ? cards.take(cap) : cards),
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
