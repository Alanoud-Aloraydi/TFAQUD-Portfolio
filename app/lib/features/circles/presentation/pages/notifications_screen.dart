import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_alert.dart';
import 'package:app/core/widgets/skeleton.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_skeletons.dart';
import 'package:app/features/circles/presentation/widgets/inbox_cards.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The notifications page: what needs an answer (invitations and requests) and
/// what the person should know (a request the patient declined). Needs an
/// [InboxCubit] above it.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// Opens the page of a request and loads the list again when the person comes
  /// back, because the answer may have changed it.
  Future<void> _open(
    BuildContext context,
    InboxCubit cubit,
    String route,
    ReceivedCircleRequest request,
  ) async {
    await context.push<void>(route, extra: request);
    if (!cubit.isClosed) cubit.load();
  }

  Future<void> _confirmCancel(
    BuildContext context,
    InboxCubit cubit,
    ReceivedCircleRequest request,
  ) async {
    final bool? yes = await showAppAlert<bool>(
      context,
      title: context.tr('circles.cancel_confirm_title'),
      message: context.tr('circles.cancel_confirm_body_patient'),
      actions: <AppAlertAction<bool>>[
        AppAlertAction<bool>(
          label: context.tr('circles.cancel_confirm_no'),
          value: false,
        ),
        AppAlertAction<bool>(
          label: context.tr('circles.cancel_confirm_yes'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (yes == true) await cubit.cancelRequest(request.id);
  }

  @override
  Widget build(BuildContext context) {
    final InboxCubit cubit = context.read<InboxCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: BlocConsumer<InboxCubit, InboxState>(
            listenWhen: (InboxState before, InboxState after) =>
                (after.sessionEnded && !before.sessionEnded) ||
                (after.errorKey != null && after.errorKey != before.errorKey),
            listener: (BuildContext context, InboxState state) {
              if (state.sessionEnded) {
                context.go(Routes.auth);
                return;
              }
              final String? key = state.errorKey;
              if (key == null) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.tr(key))));
              cubit.errorShown();
            },
            builder: (BuildContext context, InboxState state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StepHeader(
                    title: context.tr('topbar.notifications'),
                    // The page is a modal: the close button takes it down.
                    onClose: context.canPop()
                        ? () => context.pop()
                        : () => context.go(Routes.today),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    // Loading, error and content fade into each other.
                    child: ContentSwitcher(
                      stateKey: state.status,
                      child: _body(context, cubit, state),
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

  Widget _body(BuildContext context, InboxCubit cubit, InboxState state) {
    switch (state.status) {
      case InboxStatus.loading:
        return const NotificationsSkeleton();
      case InboxStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        );
      case InboxStatus.ready:
        return _list(context, cubit, state);
    }
  }

  Widget _list(BuildContext context, InboxCubit cubit, InboxState state) {
    final TextTheme text = Theme.of(context).textTheme;
    final CircleInbox inbox = state.inbox;
    final List<SentCircleRequest> declined = <SentCircleRequest>[
      for (final SentCircleRequest sent in inbox.sent)
        if (sent.status == CircleRequestStatus.declined) sent,
    ];
    final TextStyle? sectionStyle = text.titleSmall?.copyWith(
      color: AppColors.slate,
    );
    if (inbox.needsReply == 0 && declined.isEmpty) {
      return RefreshIndicator(
        onRefresh: cubit.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            const SizedBox(height: 96),
            const Icon(
              CupertinoIcons.bell,
              size: 56,
              color: AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('circles.inbox_empty'),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          if (inbox.needsReply > 0) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                context.tr(
                  'circles.needs_reply',
                  args: <String>['${inbox.needsReply}'],
                ),
                style: sectionStyle,
              ),
            ),
            for (final ReceivedInvitation invitation in inbox.invitations)
              InvitationCard(
                invitation: invitation,
                busy: state.busyIds.contains(invitation.id),
                onAccept: () =>
                    cubit.respondToInvitation(invitation.id, accept: true),
                onDecline: () =>
                    cubit.respondToInvitation(invitation.id, accept: false),
              ),
            for (final ReceivedCircleRequest request in inbox.received)
              if (request.isAccepted)
                AcceptedRequestCard(
                  request: request,
                  busy: state.busyIds.contains(request.id),
                  onContinue: () =>
                      _open(context, cubit, Routes.completeRequest, request),
                  onCancel: () => _confirmCancel(context, cubit, request),
                )
              else
                RequestCard(
                  request: request,
                  onView: () =>
                      _open(context, cubit, Routes.replyRequest, request),
                ),
          ],
          if (declined.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
              child: Text(context.tr('circles.events_title'), style: sectionStyle),
            ),
            for (final SentCircleRequest request in declined)
              DeclinedRequestCard(request: request),
          ],
        ],
      ),
    );
  }
}
