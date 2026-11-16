import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/inbox_avatar.dart';
import 'package:app/features/circles/presentation/widgets/inbox_card.dart';
import 'package:app/features/circles/presentation/widgets/needs_reply_pill.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A request that asks the person to become the patient of a circle. The
/// button opens the page that explains it and takes the answer.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onView});

  final ReceivedCircleRequest request;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => InboxCard(
    avatar: InboxAvatar(
      name: request.requesterName,
      avatarCode: request.requesterAvatarCode,
      background: AppSemanticColors.selectedSurface,
      foreground: AppSemanticColors.textPrimary,
    ),
    title: context.tr('circles.request_card_title'),
    body: context.tr(
      'circles.request_card_body',
      args: <String>[request.requesterName],
    ),
    pill: const NeedsReplyPill(),
    actions: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onView,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(AppSizes.touch),
        ),
        child: Text(context.tr('circles.view_request')),
      ),
    ),
  );
}
