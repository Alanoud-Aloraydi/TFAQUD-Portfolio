import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_skeletons.dart';
import 'package:app/features/circles/presentation/widgets/notifications_failure.dart';
import 'package:app/features/circles/presentation/widgets/notifications_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The header and the content that fits the load [state].
class NotificationsBody extends StatelessWidget {
  const NotificationsBody({
    super.key,
    required this.cubit,
    required this.state,
  });

  final InboxCubit cubit;
  final InboxState state;

  @override
  Widget build(BuildContext context) {
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
          child: ContentSwitcher(stateKey: state.status, child: _content()),
        ),
      ],
    );
  }

  Widget _content() => switch (state.status) {
    InboxStatus.loading => const NotificationsSkeleton(),
    InboxStatus.failure => NotificationsFailure(
      messageKey: state.messageKey,
      onRetry: cubit.load,
    ),
    InboxStatus.ready => NotificationsList(cubit: cubit, state: state),
  };
}
