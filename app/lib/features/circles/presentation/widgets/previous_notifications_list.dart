import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/logo_refresh.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/inbox_reply_buttons.dart';
import 'package:app/features/circles/presentation/widgets/notifications_empty.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «السابقة»: the invitations and requests answered in the last 30 days,
/// newest first, each with how long ago it was answered.
class PreviousNotificationsList extends StatelessWidget {
  const PreviousNotificationsList({
    super.key,
    required this.cubit,
    required this.state,
  });

  final InboxCubit cubit;
  final InboxState state;

  @override
  Widget build(BuildContext context) {
    final List<PreviousNotification> previous = state.inbox.previous;
    return LogoRefresh(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          if (previous.isEmpty)
            const NotificationsEmpty(messageKey: 'circles.previous_empty'),
          ...previous.map(answeredFocusCard),
          if (previous.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                context.tr('circles.previous_kept'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
