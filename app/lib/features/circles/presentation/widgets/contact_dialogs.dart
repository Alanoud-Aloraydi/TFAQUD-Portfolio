import 'package:app/core/constants/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Delete this contact?" asked before a contact leaves the medical file and
/// the emergency card. True when the person agreed.
Future<bool?> showDeleteContactDialog(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: Text(context.tr('circles.contact_delete_title')),
      content: Text(
        context.tr('circles.contact_delete_body', args: <String>[name]),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('circles.contact_delete_no')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
          child: Text(context.tr('circles.contact_delete_yes')),
        ),
      ],
    ),
  );
}
