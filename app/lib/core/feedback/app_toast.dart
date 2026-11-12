import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Whether a toast reports something that worked or something that failed.
enum ToastKind { success, error }

/// The one way the app tells the user an action finished.
///
/// The icon keeps the colour from being the only signal. A SnackBar is
/// already a live region, so VoiceOver reads the message when it appears.
abstract class AppToast {
  AppToast._();

  /// Shows the translated [messageKey] on the nearest messenger.
  static void show(
    BuildContext context,
    String messageKey, {
    ToastKind kind = ToastKind.success,
  }) => showText(
    ScaffoldMessenger.of(context),
    context.tr(messageKey),
    kind: kind,
  );

  /// Shows an already translated [message]. Use it with a messenger taken
  /// before an `await` or a navigation, when the context may be gone.
  static void showText(
    ScaffoldMessengerState messenger,
    String message, {
    ToastKind kind = ToastKind.success,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: _ToastBody(message, kind)));
  }
}

class _ToastBody extends StatelessWidget {
  const _ToastBody(this.message, this.kind);

  final String message;
  final ToastKind kind;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      // White, as the text: the toast is dark.
      Icon(
        kind == ToastKind.success
            ? Icons.check_circle_outline
            : Icons.error_outline,
        size: AppSizes.iconSmall,
        color: AppSemanticColors.surfaceContent,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(message)),
    ],
  );
}
