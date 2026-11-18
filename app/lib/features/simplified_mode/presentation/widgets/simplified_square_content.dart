import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// What a square shows: its icon, its title and its subtitle.
class SimplifiedSquareContent extends StatelessWidget {
  const SimplifiedSquareContent({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.dark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: SimplifiedStyle.head(
              SimplifiedStyle.body,
              color: dark ? SimplifiedColors.surface : SimplifiedColors.ink,
            ),
          ),
          Text(
            subtitle,
            style: SimplifiedStyle.text(
              SimplifiedStyle.caption,
              color: dark
                  ? SimplifiedColors.onDarkMuted
                  : SimplifiedColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
