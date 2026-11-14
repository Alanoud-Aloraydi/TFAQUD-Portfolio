import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The small grey header above a settings card, reusable where a page needs
/// just the title without the single-card layout `SettingsSection` assumes.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.inset,
        bottom: AppSpacing.labelGap,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: context.tokens.textSecondary),
        ),
      ),
    );
  }
}
