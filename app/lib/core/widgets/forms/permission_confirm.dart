import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Explains what a switch turns on before the phone asks for its
/// permission: the notifications, and the one-way calendar copy of a
/// circle. Both app modes show it. [keys] names the four words, such as
/// `account.notifications_confirm` for `account.notifications_confirm_title`,
/// `_text`, `_accept` and `_cancel`. False when the person says no or
/// closes it.
Future<bool> confirmPermission(BuildContext context, String keys) async {
  return await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('${keys}_title')),
          content: Text(dialogContext.tr('${keys}_text')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('${keys}_cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('${keys}_accept')),
            ),
          ],
        ),
      ) ??
      false;
}

/// Why a feature cannot work, under its switch. The way back is the switch
/// itself: turned on, it says so and leaves for the phone's Settings
/// (`leaveForSettings`), so no second button repeats it here.
class PermissionDeniedRow extends StatelessWidget {
  const PermissionDeniedRow({super.key, required this.messageKey});

  /// The sentence, such as `circle_overview.calendar_access_denied`.
  final String messageKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: AppSpacing.sm,
      start: AppSpacing.inset,
      end: AppSpacing.inset,
    ),
    child: Text(
      context.tr(messageKey),
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppSemanticColors.statusWarning),
    ),
  );
}
