import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The handle, the title and the optional message at the top of a glass
/// sheet.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({super.key, required this.title, this.message});

  final String title;
  final String? message;

  static const double _handleWidth = 36;
  static const double _handleHeight = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: _handleWidth,
              height: _handleHeight,
              decoration: ShapeDecoration(
                color: AppSemanticColors.textPrimary.withValues(alpha: 0.25),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: AppSemanticColors.textSupporting,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
