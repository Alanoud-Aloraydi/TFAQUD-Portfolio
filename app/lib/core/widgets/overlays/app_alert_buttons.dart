import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert_action.dart';
import 'package:app/core/widgets/overlays/app_alert_button.dart';
import 'package:flutter/material.dart';

/// The buttons of an alert: two short ones side by side, cancel on the right
/// and the action on the left as Arabic iOS places them; more, or long
/// labels, stack with the action on top and cancel last, as iOS 26 does.
class AppAlertButtons<T> extends StatelessWidget {
  const AppAlertButtons({super.key, required this.actions});

  final List<AppAlertAction<T>> actions;

  /// Longer labels than this stack the buttons, so none is cut.
  static const int _sideBySideLength = 14;

  @override
  Widget build(BuildContext context) {
    final bool sideBySide =
        actions.length == 2 &&
        actions.every(
          (AppAlertAction<T> a) => a.label.length <= _sideBySideLength,
        );
    // Side by side: cancel first (on the right in Arabic). Stacked: the
    // action on top, cancel last, as iOS 26 does.
    final List<AppAlertAction<T>> ordered = sideBySide
        ? <AppAlertAction<T>>[
            ...actions.where((AppAlertAction<T> a) => !a.isAction),
            ...actions.where((AppAlertAction<T> a) => a.isAction),
          ]
        : <AppAlertAction<T>>[
            ...actions.where((AppAlertAction<T> a) => a.isAction),
            ...actions.where((AppAlertAction<T> a) => !a.isAction),
          ];
    final List<Widget> buttons = <Widget>[
      for (final AppAlertAction<T> action in ordered)
        AppAlertButton<T>(action: action),
    ];
    if (sideBySide) {
      return Row(
        children: <Widget>[
          Expanded(child: buttons[0]),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: buttons[1]),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < buttons.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          buttons[i],
        ],
      ],
    );
  }
}
