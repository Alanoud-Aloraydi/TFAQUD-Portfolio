import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
