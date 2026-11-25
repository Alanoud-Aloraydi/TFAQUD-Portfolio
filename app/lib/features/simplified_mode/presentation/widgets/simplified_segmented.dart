import 'package:app/app/router/routers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_recent_readings.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Two or three big choices in one capsule («ضغط الدم | سكر الدم»).
class SimplifiedSegmented<T> extends StatelessWidget {
  const SimplifiedSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SimplifiedColors.surface.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: SimplifiedColors.control, width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          for (final MapEntry<T, String> entry in segments.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == selected,
                child: GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: SimplifiedStyle.touch,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == selected
                          ? SimplifiedColors.surface
                          : SimplifiedColors.clear,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      entry.value,
                      style: entry.key == selected
                          ? SimplifiedStyle.head(SimplifiedStyle.body)
                          : SimplifiedStyle.text(
                              SimplifiedStyle.body,
                              color: SimplifiedColors.ink,
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
