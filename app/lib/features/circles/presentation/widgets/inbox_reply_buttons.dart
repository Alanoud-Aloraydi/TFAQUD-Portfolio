import 'package:app/core/reminders/item_keys.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/presentation/widgets/previous_notification_card.dart';
import 'package:flutter/material.dart';

/// Accept and decline side by side. While [busy] both are off and the accept
/// button turns; [danger] paints the second one red, for an answer that
/// cannot be taken back.
class InboxReplyButtons extends StatelessWidget {
  const InboxReplyButtons({
    super.key,
    required this.acceptLabel,
    required this.declineLabel,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    this.danger = false,
  });

  final String acceptLabel;
  final String declineLabel;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool danger;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: FilledButton(
          onPressed: busy ? null : onAccept,
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(AppSizes.touch),
          ),
          child: busy
              ? const SizedBox(
                  width: AppSpacing.space5,
                  height: AppSpacing.space5,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.spinnerStroke,
                    color: AppSemanticColors.onActionPrimary,
                  ),
                )
              : Text(acceptLabel),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: OutlinedButton(
          onPressed: busy ? null : onDecline,
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(AppSizes.touch),
            foregroundColor: danger
                ? AppSemanticColors.statusError
                : AppSemanticColors.textPrimary,
            side: const BorderSide(color: AppSemanticColors.borderControlBase),
          ),
          child: Text(declineLabel),
        ),
      ),
    ],
  );
}

/// A card of the bell's «الحالية», keyed by its invitation's or request's
/// id, brought into view and outlined when the notification just tapped is
/// about it ([FocusMark]).
Widget inboxFocusMark(Widget card) => switch (card.key) {
  ValueKey<String>(:final String value) => _marked(inboxItemKey(value), card),
  _ => card,
};

/// An entry of «السابقة», marked the same way when it is a tapped answer.
Widget answeredFocusCard(PreviousNotification item) => _marked(
  answeredItemKey(item.id),
  PreviousNotificationCard(key: ValueKey<String>(item.id), item: item),
);

/// Each card keeps a margin under it, which the outline leaves out.
Widget _marked(String itemKey, Widget card) => FocusMark(
  key: ValueKey<String>('mark:$itemKey'),
  itemKey: itemKey,
  radius: AppRadius.card,
  inset: const EdgeInsets.only(bottom: AppSpacing.md),
  child: card,
);
