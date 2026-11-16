import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Explains the one-way calendar copy before it is enabled for a circle.
/// Both app modes show it through `CalendarSyncChoices`.
Future<bool> confirmCalendarSync(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            dialogContext.tr('circle_overview.calendar_sync_confirm_title'),
          ),
          content: Text(
            dialogContext.tr('circle_overview.calendar_sync_confirm_text'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                dialogContext.tr(
                  'circle_overview.calendar_sync_confirm_cancel',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                dialogContext.tr(
                  'circle_overview.calendar_sync_confirm_accept',
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;
}
