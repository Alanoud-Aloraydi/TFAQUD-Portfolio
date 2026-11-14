import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The small rounded square with an icon at the start of a settings row,
/// as in iOS Settings: it tells the rows apart at a glance. Decorative: the
/// row's label says what it is.
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({
    super.key,
    required this.icon,
    required this.background,
  });

  /// iOS Settings' icon square: 29 points, its corners about a quarter.
  static const double size = 30;
  static const double radius = 8;

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.onSettingsTile,
        ),
      ),
    );
  }
}
