import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Asks to confirm leaving the circle, or deleting it when the person
/// leaving is its patient or its last member. True means go ahead.
Future<bool?> askLeaveConfirmation(BuildContext context, bool deletesCircle) {
  final String kind = deletesCircle ? 'delete' : 'leave';
  return showAppAlert<bool>(
    context,
    title: context.tr('circle_overview.${kind}_title'),
    message: context.tr('circle_overview.${kind}_message'),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr(
          deletesCircle
              ? 'circle_overview.delete_confirm'
              : 'circle_overview.leave',
        ),
        value: true,
        destructive: true,
      ),
    ],
  );
}
