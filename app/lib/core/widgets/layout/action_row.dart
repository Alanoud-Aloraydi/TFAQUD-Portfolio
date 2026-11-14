import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A row that is only a text button, such as "تسجيل الخروج".
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppSemanticColors.textPrimary,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return InkWell(
      onTap: busy ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: text.titleMedium?.copyWith(color: color),
              ),
            ),
            if (busy)
              const SizedBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
