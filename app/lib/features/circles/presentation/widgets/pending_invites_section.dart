import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/inbox_cards.dart';
import 'package:app/features/circles/presentation/widgets/inbox_reply_buttons.dart';
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

/// A card for each invitation and each received request that needs a
/// reply, invitations first. An accepted invitation calls [onAccepted].
List<Widget> pendingInviteCards(
  BuildContext context, {
  required InboxCubit cubit,
  required InboxState state,
  VoidCallback? onAccepted,
}) => <Widget>[
  for (final ReceivedInvitation invitation in state.inbox.invitations)
    InvitationCard(
      key: ValueKey(invitation.id),
      invitation: invitation,
      busy: state.busyIds.contains(invitation.id),
      onAccept: () => acceptInvitation(
        context,
        cubit,
        invitation.id,
        onAccepted: onAccepted,
      ),
      onDecline: () => declineInvitation(context, cubit, invitation.id),
    ),
  for (final ReceivedCircleRequest request in state.inbox.received)
    if (request.isAccepted)
      AcceptedRequestCard(
        key: ValueKey(request.id),
        request: request,
        busy: state.busyIds.contains(request.id),
        onContinue: () => openReceivedRequest(
          context,
          cubit,
          Routes.completeRequest,
          request,
        ),
        onCancel: () => confirmCancelRequest(context, cubit, request),
      )
    else
      RequestCard(
        key: ValueKey(request.id),
        request: request,
        onView: () =>
            openReceivedRequest(context, cubit, Routes.replyRequest, request),
      ),
];

/// Accepts the invitation and says so; then [onAccepted], if any, leaves
/// for the circle.
Future<void> acceptInvitation(
  BuildContext context,
  InboxCubit cubit,
  String invitationId, {
  VoidCallback? onAccepted,
}) async {
  final bool accepted = await cubit.respondToInvitation(
    invitationId,
    accept: true,
  );
  if (!accepted) return;
  if (context.mounted) AppToast.show(context, 'toast.invite_accepted');
  onAccepted?.call();
}

/// Declines the invitation and says so.
Future<void> declineInvitation(
  BuildContext context,
  InboxCubit cubit,
  String invitationId,
) async {
  final bool declined = await cubit.respondToInvitation(
    invitationId,
    accept: false,
  );
  if (declined && context.mounted) {
    AppToast.show(context, 'toast.invite_declined');
  }
}

/// Opens the page of a received request at [route], then reads the inbox
/// again for what that page changed.
Future<void> openReceivedRequest(
  BuildContext context,
  InboxCubit cubit,
  String route,
  ReceivedCircleRequest request,
) async {
  await context.push<void>(route, extra: request);
  if (!cubit.isClosed) cubit.load();
}

/// Asks the patient to confirm, then cancels the request they had accepted.
Future<void> confirmCancelRequest(
  BuildContext context,
  InboxCubit cubit,
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
  if (yes != true) return;
  final bool canceled = await cubit.cancelRequest(request.id);
  if (canceled && context.mounted) {
    AppToast.show(context, 'toast.request_canceled');
  }
}
