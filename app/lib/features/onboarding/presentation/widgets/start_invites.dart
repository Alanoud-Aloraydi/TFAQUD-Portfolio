import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/pending_invites_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The invitations waiting for the person, above the choice of the start
/// step. Nothing waiting: nothing shows, and no gap either.
class StartInvites extends StatelessWidget {
  const StartInvites({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxCubit, InboxState>(
      builder: (BuildContext context, InboxState inboxState) {
        if (inboxState.status != InboxStatus.ready ||
            inboxState.inbox.needsReply == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          // Capped to a short teaser so many pending invitations don't push
          // the choice below out of reach; "عرض الكل" opens the full
          // notifications list for the rest.
          child: PendingInvitesSection(
            cubit: context.read<InboxCubit>(),
            state: inboxState,
            maxItems: 2,
            // The circle is chosen: no reason to stay and pick "self/other".
            onAccepted: () => context.go(Routes.today),
          ),
        );
      },
    );
  }
}
