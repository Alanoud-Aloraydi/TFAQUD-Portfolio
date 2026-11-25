import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:flutter/material.dart';

/// The detailed mode's settings icon square (SettingsIconTile), in this
/// mode's size: a kind's icon on its colour ([CareVisuals]). Decorative:
/// the row's words say what it is.
class CareIconTile extends StatelessWidget {
  const CareIconTile({
    super.key,
    required this.icon,
    required this.background,
    this.size = 44,
  });

  final IconData icon;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          // A quarter of the side, as iOS Settings' squares.
          borderRadius: BorderRadius.circular(size / 4),
        ),
        child: Icon(icon, size: size / 2, color: AppSettingsTileColors.onTile),
      ),
    );
  }
}
