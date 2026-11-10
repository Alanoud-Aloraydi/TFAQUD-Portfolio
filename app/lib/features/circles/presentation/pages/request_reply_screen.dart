import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page of a request addressed to the signed-in person (CREAT-06): who
/// asks, the name of the circle, the mode proposed for the patient's app, and
/// the two answers. Agreeing leads to the basic data; declining goes back.
/// Needs a [RequestReplyCubit] above it.
class RequestReplyScreen extends StatelessWidget {
  const RequestReplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestReplyCubit cubit = context.read<RequestReplyCubit>();
    final ReceivedCircleRequest request = cubit.request;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocConsumer<RequestReplyCubit, RequestReplyState>(
            listenWhen: (RequestReplyState before, RequestReplyState after) =>
                (after.sessionEnded && !before.sessionEnded) ||
                (after.outcome != before.outcome &&
                    after.outcome != ReplyOutcome.none),
            listener: (BuildContext context, RequestReplyState state) {
              if (state.sessionEnded) {
                context.go(Routes.auth);
              } else if (state.outcome == ReplyOutcome.accepted) {
                context.pushReplacement(Routes.completeRequest, extra: request);
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.notifications);
              }
            },
            builder: (BuildContext context, RequestReplyState state) {
              final TextTheme text = Theme.of(context).textTheme;
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            title: context.tr('circles.reply_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : () => context.go(Routes.notifications),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _RequestDetails(request: request),
                          const SizedBox(height: AppSpacing.lg),
                          InsetText(
                            context.tr('circles.reply_decline_note'),
                            style: text.bodyMedium?.copyWith(
                              color: context.tokens.textSecondary,
                            ),
                          ),
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
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
                        side: const BorderSide(
                          color: AppSemanticColors.borderControlBase,
                        ),
                      ),
                      child: Text(context.tr('circles.decline')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The card with the sender, the circle name, the mode, and what the sender
/// will be able to do.
class _RequestDetails extends StatelessWidget {
  const _RequestDetails({required this.request});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: AppSizes.avatarLarge,
                height: AppSizes.avatarLarge,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppSemanticColors.selectedSurface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? '؟' : name.characters.first,
                  style: text.titleLarge?.copyWith(
                    color: AppSemanticColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(name, style: text.titleMedium),
                    ),
                    Text(
                      context.tr('circles.reply_subtitle'),
                      style: text.bodyMedium?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // No circle name here: the patient names the circle when they
          // complete the request.
          const Divider(height: 32),
          _Row(
            label: context.tr('circles.reply_mode'),
            child: StatusPill(
              text: context.tr(
                detailed ? 'circles.mode_detailed' : 'circles.mode_simplified',
              ),
              background: AppSemanticColors.selectedSurface,
              foreground: AppSemanticColors.textPrimary,
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
    );
  }
}

/// Renders the row element of request reply screen.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.tokens.textSecondary),
          ),
        ),
        child,
      ],
    );
  }
}
