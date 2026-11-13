import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The large title at the top of each tab, under the floating glass
/// controls (design system TopBar): the tab's name in large-title (34 bold),
/// and an optional line under it, such as today's date. It scrolls with the
/// content.
class LargeTitle extends StatelessWidget {
  const LargeTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleTrailing,
  });

  final String title;
  final String? subtitle;

  /// Beside [subtitle] on its line, such as the weather by the date; it
  /// wraps under it when the line is full.
  final Widget? subtitleTrailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(header: true, child: Text(title, style: text.displaySmall)),
          if (subtitle != null && subtitleTrailing == null)
            Text(subtitle!, style: text.bodySmall),
          if (subtitleTrailing case final Widget trailing)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: <Widget>[
                if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                trailing,
              ],
            ),
        ],
      ),
    );
  }
}
