import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:flutter/widgets.dart';

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
