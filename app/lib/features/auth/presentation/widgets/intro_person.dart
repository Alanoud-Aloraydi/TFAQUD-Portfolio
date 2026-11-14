import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/intro_initial.dart';
import 'package:flutter/material.dart';

/// A person: a round letter, the name, a small line under it, and maybe
/// something at the end.
class IntroPerson extends StatelessWidget {
  const IntroPerson({
    super.key,
    required this.initial,
    required this.color,
    required this.name,
    required this.note,
    this.size = AppSizes.avatar,
    this.trailing,
  });

  final String initial;
  final Color color;
  final String name;
  final String note;
  final double size;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget? end = trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          IntroInitial(letter: initial, color: color, size: size),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: text.titleSmall),
                Text(note, style: text.bodySmall),
              ],
            ),
          ),
          ?end,
        ],
      ),
    );
  }
}
