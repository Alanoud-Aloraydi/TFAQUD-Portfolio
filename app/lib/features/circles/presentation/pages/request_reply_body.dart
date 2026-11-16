import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:app/features/circles/presentation/widgets/request_details_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The scrolling part of the request page: header, details card, the note
/// about declining and the error line.
List<Widget> requestReplyBody(
  BuildContext context,
  RequestReplyState state,
  ReceivedCircleRequest request,
) {
  final TextTheme text = Theme.of(context).textTheme;
  return <Widget>[
    StepHeader(
      title: context.tr('circles.reply_title'),
      onBack: context.canPop()
          ? () => context.pop()
          : () => context.go(Routes.notifications),
    ),
    const SizedBox(height: AppSpacing.xl),
    RequestDetails(request: request),
    const SizedBox(height: AppSpacing.lg),
    InsetText(
      context.tr('circles.reply_decline_note'),
      style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
    ),
    if (state.errorKey != null) ...<Widget>[
      const SizedBox(height: AppSpacing.lg),
      InlineError(messageKey: state.errorKey!),
    ],
  ];
}
