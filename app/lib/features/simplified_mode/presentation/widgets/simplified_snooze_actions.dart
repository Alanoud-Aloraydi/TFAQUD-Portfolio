import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dark_outline_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «ذكّرني», the detailed sheet's own button, and «رجوع» under it, which
/// puts nothing off.
class SimplifiedSnoozeActions extends StatelessWidget {
  const SimplifiedSnoozeActions({super.key, required this.onConfirm});

  /// Null while it is being saved, and when there is no room to put the
  /// task off.
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      SimplifiedButton(
        label: context.tr('reminders.snooze_confirm'),
        tone: SimplifiedButtonTone.answer,
        onPressed: onConfirm,
      ),
      const SizedBox(height: 12),
      SimplifiedDarkOutlineButton(
        label: context.tr('simplified_mode.back'),
        onPressed: () => context.go(Routes.simplifiedMode),
      ),
    ],
  );
}
