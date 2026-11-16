import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/home_add_quick_action_row.dart';
import 'package:flutter/material.dart';

/// «سجّل قراءة الآن»: the quick action, on ink with a leaf icon tile.
class HomeAddQuickAction extends StatelessWidget {
  const HomeAddQuickAction({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: spoken('$title، $hint'),
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: AppSemanticColors.textPrimary,
      shape: AppRadius.shape(AppRadius.m),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: MergeSemantics(
            child: Row(
              children: homeAddQuickActionRow(
                context,
                icon: icon,
                title: title,
                hint: hint,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
