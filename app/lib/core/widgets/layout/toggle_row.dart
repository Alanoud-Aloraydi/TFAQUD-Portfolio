import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A row with a label, an optional hint below it, and a switch at the end;
/// [leading] (a [SettingsIconTile]) before the label.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.leading,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      toggled: value,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            if (leading case final Widget leading) ...<Widget>[
              leading,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: text.bodyLarge),
                  if (hint case final String hint) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hint,
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ExcludeSemantics(
              child: CupertinoSwitch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
