import 'package:app/core/widgets/app_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Delete this contact?" asked before a contact leaves the medical file and
/// the emergency card. True when the person agreed.
Future<bool?> showDeleteContactDialog(BuildContext context, String name) {
  return showAppAlert<bool>(
    context,
    title: context.tr('circles.contact_delete_title'),
    message: context.tr('circles.contact_delete_body', args: <String>[name]),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(
        label: context.tr('circles.contact_delete_no'),
        value: false,
      ),
      AppAlertAction<bool>(
        label: context.tr('circles.contact_delete_yes'),
        value: true,
        primary: true,
      ),
    ],
  );
}
