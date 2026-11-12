import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_skeletons.dart';
import 'package:app/features/circles/presentation/widgets/notifications_failure.dart';
import 'package:app/features/circles/presentation/widgets/notifications_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The two lists of the bell: what waits for an answer, and what was
/// answered in the last 30 days.
enum NotificationsTab { current, previous }

/// The header, the two tabs, and the content that fits the load [state].
/// The page opens on «الحالية».
class NotificationsBody extends StatefulWidget {
  const NotificationsBody({
    super.key,
    required this.cubit,
    required this.state,
  });

  final InboxCubit cubit;
  final InboxState state;

  @override
  State<NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<NotificationsBody> {
  NotificationsTab _tab = NotificationsTab.current;

  @override
  Widget build(BuildContext context) {
    final InboxState state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StepHeader(
          title: context.tr('topbar.notifications'),
          // The page is a modal: the close button takes it down.
          onClose: context.canPop()
              ? () => context.pop()
              : () => context.go(Routes.today),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassSegmentedControl<NotificationsTab>(
          segments: <NotificationsTab, String>{
            NotificationsTab.current: context.tr('circles.tab_current'),
            NotificationsTab.previous: context.tr('circles.tab_previous'),
          },
          // How many wait for an answer, beside «الحالية».
          counts: state.inbox.needsReply == 0
              ? null
              : <NotificationsTab, int>{
                  NotificationsTab.current: state.inbox.needsReply,
                },
          selected: _tab,
          onChanged: (NotificationsTab tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ContentSwitcher(
            stateKey: (state.status, _tab),
            child: _content(state),
          ),
        ),
      ],
    );
  }

  Widget _content(InboxState state) => switch (state.status) {
    InboxStatus.loading => const NotificationsSkeleton(),
    InboxStatus.failure => NotificationsFailure(
      messageKey: state.messageKey,
      onRetry: widget.cubit.load,
    ),
    InboxStatus.ready =>
      _tab == NotificationsTab.current
          ? NotificationsList(cubit: widget.cubit, state: state)
          : PreviousNotificationsList(cubit: widget.cubit, state: state),
  };
}
