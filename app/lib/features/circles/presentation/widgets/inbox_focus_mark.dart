import 'package:app/core/services/reminders/item_keys.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/focus_mark.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/presentation/widgets/previous_notification_card.dart';
import 'package:flutter/widgets.dart';

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
