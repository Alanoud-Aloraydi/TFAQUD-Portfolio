import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What the person chose in the leave alert.
enum LeaveCircleChoice {
  /// Nothing happens.
  cancel,

  /// Take the record out first; the circle is not left.
  export,

  /// Leave, which deletes the circle when they are its patient or its last
  /// member.
  leave,
}

/// Asks to confirm leaving the circle, or deleting it when the person
/// leaving is its patient or its last member.
///
/// Leaving deletes the data with it, so that alert also offers to export
/// the record first; the ordinary one has nothing to save.
Future<LeaveCircleChoice?> askLeaveConfirmation(
  BuildContext context,
  bool deletesCircle,
) {
  final String kind = deletesCircle ? 'delete' : 'leave';
  return showAppAlert<LeaveCircleChoice>(
    context,
    title: context.tr('circle_overview.${kind}_title'),
    message: context.tr('circle_overview.${kind}_message'),
    actions: <AppAlertAction<LeaveCircleChoice>>[
      AppAlertAction<LeaveCircleChoice>(
        label: context.tr('common.cancel'),
        value: LeaveCircleChoice.cancel,
      ),
      if (deletesCircle)
        AppAlertAction<LeaveCircleChoice>(
          label: context.tr('circle_overview.export_before_leaving'),
          value: LeaveCircleChoice.export,
        ),
      AppAlertAction<LeaveCircleChoice>(
        label: context.tr(
          deletesCircle
              ? 'circle_overview.delete_confirm'
              : 'circle_overview.leave',
        ),
        value: LeaveCircleChoice.leave,
        destructive: true,
      ),
    ],
  );
}
