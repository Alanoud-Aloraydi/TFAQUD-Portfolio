import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:app/features/circles/presentation/widgets/request_details_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The scrolling part of the request page: header, details card and the
/// note about declining. A refused answer is a toast: no field is wrong.
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
    ErrorToast(
      errorKey: state.errorKey,
      child: InsetText(
        context.tr('circles.reply_decline_note'),
        style: text.bodyMedium?.copyWith(color: context.tokens.textSecondary),
      ),
    ),
  ];
}

/// The two answers under the scrolling part: agree, and decline.
List<Widget> requestReplyActions(
  BuildContext context,
  RequestReplyState state,
  RequestReplyCubit cubit,
) {
  return <Widget>[
    const SizedBox(height: AppSpacing.lg),
    PillButton(
      label: context.tr('circles.accept_request'),
      isLoading: state.sending,
      onPressed: cubit.accept,
    ),
    const SizedBox(height: AppSpacing.md),
    SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: state.sending ? null : cubit.decline,
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppSemanticColors.textPrimary,
          side: const BorderSide(color: AppSemanticColors.borderControlBase),
        ),
        child: Text(context.tr('circles.decline')),
      ),
    ),
  ];
}
