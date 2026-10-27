import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:app/features/circles/presentation/widgets/status_pill.dart';
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                          const SizedBox(height: 24),
                          _RequestDetails(request: request),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('circles.reply_decline_note'),
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: 16),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: context.tr('circles.accept_request'),
                    isLoading: state.sending,
                    onPressed: cubit.accept,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: state.sending ? null : cubit.decline,
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.dangerInk,
                        side: const BorderSide(color: AppColors.danger),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.brandTint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? '؟' : name.characters.first,
                  style: text.titleLarge?.copyWith(color: AppColors.brand),
                ),
              ),
              const SizedBox(width: 12),
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
                      style: text.bodyMedium?.copyWith(color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _Row(
            label: context.tr('circles.approved_circle_name'),
            child: StatusPill(
              text: request.circleName,
              background: AppColors.sunken,
              foreground: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            label: context.tr('circles.reply_mode'),
            child: StatusPill(
              text: context.tr(
                detailed ? 'circles.mode_detailed' : 'circles.mode_simplified',
              ),
              background: AppColors.brandTint,
              foreground: AppColors.brand,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              detailed
                  ? 'circles.reply_body_detailed'
                  : 'circles.reply_body_simplified',
            ),
            style: text.bodyMedium?.copyWith(color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.ink2),
          ),
        ),
        child,
      ],
    );
  }
}
