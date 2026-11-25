import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert_action.dart';
import 'package:app/core/widgets/overlays/app_alert_buttons.dart';
import 'package:app/core/widgets/overlays/app_alert_transition.dart';
import 'package:flutter/material.dart';

export 'package:app/core/widgets/overlays/app_alert_action.dart';

/// Shows the app's alert (design system Alert), in the iOS 26 style: a
/// white panel with large concentric corners, a short title and message, and
/// capsule buttons. Two buttons sit side by side, cancel on the right and
/// the action on the left, as Arabic iOS places them; more, or long labels,
/// stack with the action on top.
///
/// It fades in with a slight spring from a little larger than its size, over
/// a soft dim, and fades out; with Reduce Motion on, it only fades. Tapping
/// outside does nothing, as in iOS. Returns the tapped button's value.
Future<T?> showAppAlert<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<AppAlertAction<T>> actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: AppSemanticColors.overlayScrim,
    transitionDuration: AppMotion.alert,
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) => AppAlert<T>(title: title, message: message, actions: actions),
    transitionBuilder: appAlertTransition,
  );
}

/// The alert panel. Use [showAppAlert] to open it.
class AppAlert<T> extends StatelessWidget {
  const AppAlert({
    super.key,
    required this.title,
    this.message,
    required this.actions,
  });

  final String title;
  final String? message;
  final List<AppAlertAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.alertWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: AppAlertPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppAlertText(title: title, message: message),
                  const SizedBox(height: AppSpacing.space5),
                  AppAlertButtons<T>(actions: actions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
