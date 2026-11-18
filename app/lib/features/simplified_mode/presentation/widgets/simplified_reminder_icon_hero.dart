import 'package:flutter/material.dart';
import 'package:app/core/theme/app_settings_tile_colors.dart';

/// The picture of a task that has no photo: its kind's icon on its kind's
/// colour (CareVisuals), filling the reminder's frame.
class SimplifiedReminderIconHero extends StatelessWidget {
  const SimplifiedReminderIconHero({
    super.key,
    required this.icon,
    required this.ground,
    required this.height,
  });

  final IconData icon;
  final Color ground;
  final double height;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ground,
    child: Center(
      child: Icon(
        icon,
        size: height * .45,
        color: AppSettingsTileColors.onTile,
      ),
    ),
  );
}
