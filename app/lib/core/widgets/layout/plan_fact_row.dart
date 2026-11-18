import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The size of a fact's icon tile and of a person's photo beside a fact.
const double planFactLeadingSize = 32;

/// One row of a plan fact: the [leading] widget, then label, value and more.
class PlanFactRow extends StatelessWidget {
  const PlanFactRow({
    super.key,
    required this.leading,
    this.label,
    this.value,
    this.trailing,
    this.below,
  });

  final Widget leading;
  final String? label;
  final String? value;
  final Widget? trailing;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (label case final String words)
                    Text(
                      words,
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  if (value case final String shown)
                    Text(
                      shown,
                      style: text.titleSmall?.copyWith(
                        fontWeight: AppTextTheme.bold,
                      ),
                      semanticsLabel: spoken(shown),
                    ),
                  if (below case final Widget under) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    under,
                  ],
                ],
              ),
            ),
            if (trailing case final Widget end) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              end,
            ],
          ],
        ),
      ),
    );
  }
}
