import 'package:app/app/router/routers.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/inbox_cards.dart';
import 'package:app/features/circles/presentation/widgets/received_request_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
