import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/widgets/back_link.dart';
import 'package:flutter/material.dart';

/// Top of a step page: optional back link, title, optional subtitle.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;

  /// Null hides the back link and keeps its space, so titles line up.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (onBack != null)
          BackLink(onPressed: onBack!)
        else
          const SizedBox(height: 44),
        const SizedBox(height: 12),
        Semantics(header: true, child: Text(title, style: text.headlineMedium)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: AppColors.ink2),
          ),
        ],
      ],
    );
  }
}
