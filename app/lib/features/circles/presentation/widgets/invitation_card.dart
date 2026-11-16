import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/presentation/widgets/inbox_avatar.dart';
import 'package:app/features/circles/presentation/widgets/inbox_card.dart';
import 'package:app/features/circles/presentation/widgets/inbox_reply_buttons.dart';
import 'package:app/features/circles/presentation/widgets/needs_reply_pill.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// An invitation to manage a circle, answered on the card.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.invitation,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ReceivedInvitation invitation;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final String by = invitation.invitedByName?.trim() ?? '';
    return InboxCard(
      avatar: InboxAvatar(
        name: by,
        avatarCode: invitation.invitedByAvatarCode,
        background: AppSemanticColors.selectedSurface,
        foreground: AppSemanticColors.textPrimary,
      ),
      title: context.tr('circles.invitation_title'),
      body: by.isEmpty
          ? context.tr(
              'circles.invitation_body',
              args: <String>[invitation.circleName],
            )
          : context.tr(
              'circles.invitation_body_by',
              args: <String>[by, invitation.circleName],
            ),
      pill: const NeedsReplyPill(),
      actions: InboxReplyButtons(
        acceptLabel: context.tr('circles.accept'),
        declineLabel: context.tr('circles.decline'),
        busy: busy,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }
}
