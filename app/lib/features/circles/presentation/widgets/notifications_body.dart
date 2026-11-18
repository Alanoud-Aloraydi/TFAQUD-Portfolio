import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/notifications_tab.dart';
import 'package:app/features/circles/presentation/widgets/notifications_content.dart';
import 'package:app/features/circles/presentation/widgets/notifications_tabs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The header, the two tabs, and the content that fits the load [state].
/// The page opens on the tab [NotificationsTab.startFor] picks.
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
  late NotificationsTab _tab = NotificationsTab.startFor(widget.state.inbox);

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
        NotificationsTabs(
          selected: _tab,
          needsReply: state.inbox.needsReply,
          onChanged: (NotificationsTab tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ContentSwitcher(
            stateKey: (state.status, _tab),
            child: NotificationsContent(
              cubit: widget.cubit,
              state: state,
              tab: _tab,
            ),
          ),
        ),
      ],
    );
  }
}
