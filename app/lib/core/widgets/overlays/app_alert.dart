import 'dart:ui' show lerpDouble;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One button of an [AppAlert].
class AppAlertAction<T> {
  const AppAlertAction({
    required this.label,
    this.value,
    this.primary = false,
    this.destructive = false,
  });

  final String label;

  /// What [showAppAlert] returns when this button is tapped.
  final T? value;

  /// The action the alert asks about, such as «حفظ»: an ink capsule. The
  /// others are light grey capsules.
  final bool primary;

  /// The action deletes something or cannot be undone, such as «حذف»,
  /// «تسجيل الخروج» or «تجاهل التغييرات»: a light grey capsule with its
  /// label in the error red (#A53636, 4.98:1 on the grey), as iOS draws a
  /// destructive action. It takes the place of the action the alert asks
  /// about.
  final bool destructive;

  /// Whether this is the action the alert asks about (not the way out).
  bool get isAction => primary || destructive;
}

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
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final bool still = MediaQuery.disableAnimationsOf(context);
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final bool closing = animation.status == AnimationStatus.reverse;
              final double opacity = AppMotion.easeOut.transform(
                animation.value,
              );
              if (still) return Opacity(opacity: opacity, child: child);
              // Opening: from 108% down to its size with a small overshoot.
              // Closing: a slight shrink while it fades.
              final double scale = closing
                  ? lerpDouble(AppMotion.alertClosingScale, 1, animation.value)!
                  : lerpDouble(
                      AppMotion.alertOpeningScale,
                      1,
                      AppMotion.alertSpring.transform(animation.value),
                    )!;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: child,
          );
        },
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

  /// Longer labels than this stack the buttons, so none is cut.
  static const int _sideBySideLength = 14;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
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
        _AlertButton<T>(action: action),
    ];
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
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: AppRadius.shape(AppRadius.xl),
                  color: AppSemanticColors.surfaceContent,
                  shadows: AppEffects.alertPanelShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Text 16 from the panel's edge: 12 + 4.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Column(
                          children: <Widget>[
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: text.titleLarge,
                            ),
                            if (message != null) ...<Widget>[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: text.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space5),
                      if (sideBySide)
                        Row(
                          children: <Widget>[
                            Expanded(child: buttons[0]),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: buttons[1]),
                          ],
                        )
                      else
                        for (int i = 0; i < buttons.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(height: AppSpacing.sm),
                          buttons[i],
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the alert button element of app alert.
class _AlertButton<T> extends StatelessWidget {
  const _AlertButton({required this.action});

  final AppAlertAction<T> action;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(action.label, textAlign: TextAlign.center);
    void tap() => Navigator.of(context).pop(action.value);
    const Size size = Size.fromHeight(AppSizes.compactButton);
    if (action.primary && !action.destructive) {
      return FilledButton(
        onPressed: tap,
        style: FilledButton.styleFrom(minimumSize: size),
        child: label,
      );
    }
    return FilledButton(
      onPressed: tap,
      style:
          FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: AppSemanticColors.borderSubtle,
            foregroundColor: action.destructive
                ? context.tokens.errorText
                : AppSemanticColors.textPrimary,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll<Color>(
              AppEffects.interactionOverlay,
            ),
          ),
      child: label,
    );
  }
}
