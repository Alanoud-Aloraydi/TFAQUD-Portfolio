import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/material.dart';

/// A rounded square with an icon, as on the dose and reading cards.
class IntroTile extends StatelessWidget {
  const IntroTile({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: ShapeDecoration(
        color: background,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Icon(icon, size: AppSizes.iconSmall, color: foreground),
    );
  }
}
