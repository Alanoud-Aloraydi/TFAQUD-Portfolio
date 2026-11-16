import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/inbox_avatar.dart';
import 'package:app/features/circles/presentation/widgets/inbox_card.dart';
import 'package:app/features/circles/presentation/widgets/inbox_reply_buttons.dart';
import 'package:app/features/circles/presentation/widgets/needs_reply_pill.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A request the person agreed to and has not finished: the basic data is
/// missing, so the circle does not exist yet. The patient names the circle
/// on the next page.
class AcceptedRequestCard extends StatelessWidget {
  const AcceptedRequestCard({
    super.key,
    required this.request,
    required this.busy,
    required this.onContinue,
    required this.onCancel,
  });

  final ReceivedCircleRequest request;
  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => InboxCard(
    avatar: InboxAvatar(
      name: request.requesterName,
      avatarCode: request.requesterAvatarCode,
      background: AppSemanticColors.selectedSurface,
      foreground: AppSemanticColors.textPrimary,
    ),
    title: context.tr('circles.complete_card_title'),
    body: context.tr(
      'circles.complete_card_body',
      args: <String>[request.requesterName],
    ),
    pill: const NeedsReplyPill(),
    actions: InboxReplyButtons(
      acceptLabel: context.tr('common.continue'),
      declineLabel: context.tr('circles.cancel_request'),
      busy: busy,
      danger: true,
      onAccept: onContinue,
      onDecline: onCancel,
    ),
  );
}
