import 'package:app/core/feedback/app_toast.dart';
import 'package:flutter/widgets.dart';

/// Tells the leader how a change to a member went: [doneKey] in a toast,
/// or the error in a red one.
void showMemberActionResult(
  BuildContext context,
  String? errorKey,
  String doneKey,
) {
  if (!context.mounted) return;
  if (errorKey == null) {
    AppToast.show(context, doneKey);
    return;
  }
  AppToast.show(context, errorKey, kind: ToastKind.error);
}
