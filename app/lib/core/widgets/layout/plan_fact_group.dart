import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_fact_row.dart';
import 'package:flutter/material.dart';

/// One titled group of a plan card's opened details: «الجدول», «عن الدواء»,
/// «الأشخاص». Related facts sit together in one tinted box, divided by
/// lines, as Apple groups them in its lists, so the eye finds a group
/// first, then the fact.
class PlanFactGroup extends StatelessWidget {
  const PlanFactGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.tokens.textSecondary,
              fontWeight: AppTextTheme.semibold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: AppSemanticColors.background,
            shape: AppRadius.shape(AppRadius.s),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: AppSizes.divider,
                      indent: planFactLeadingSize + AppSpacing.md,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
