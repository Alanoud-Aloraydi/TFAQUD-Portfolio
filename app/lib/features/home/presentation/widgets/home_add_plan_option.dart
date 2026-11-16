import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/home_add_plan_option_row.dart';
import 'package:flutter/material.dart';

/// One plan: an icon tile, the name and what it does, and a chevron.
class HomeAddPlanOption extends StatelessWidget {
  const HomeAddPlanOption({
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
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: MergeSemantics(
          child: Row(
            children: homeAddPlanOptionRow(
              context,
              icon: icon,
              title: title,
              hint: hint,
            ),
          ),
        ),
      ),
    ),
  );
}
