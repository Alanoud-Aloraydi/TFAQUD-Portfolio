import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/request_reply_row.dart';
import 'package:app/features/circles/presentation/widgets/request_sender_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The card with the sender, the circle name, the mode, and what the sender
/// will be able to do.
class RequestDetails extends StatelessWidget {
  const RequestDetails({super.key, required this.request});

  final ReceivedCircleRequest request;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool detailed = request.proposedAppMode == CircleAppMode.detailed;
    final String name = request.requesterName.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            requestSenderRow(context, name),
            // No circle name here: the patient names the circle when they
            // complete the request.
            const Divider(height: 32),
            RequestReplyRow(
              label: context.tr('circles.reply_mode'),
              child: StatusBadge(
                text: context.tr(
                  detailed
                      ? 'circles.mode_detailed'
                      : 'circles.mode_simplified',
                ),
                tone: StatusTone.success,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr(
                detailed
                    ? 'circles.reply_body_detailed'
                    : 'circles.reply_body_simplified',
              ),
              style: text.bodyMedium?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
