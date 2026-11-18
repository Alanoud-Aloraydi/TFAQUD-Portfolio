import 'package:app/core/constants/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:app/core/theme/app_settings_tile_colors.dart';

/// How each kind of care looks, the same in the detailed and the simplified
/// mode: medicines a pill on green, measurements a heartbeat on honey,
/// appointments a calendar on grey. Icons on these tiles use
/// [AppSettingsTileColors.onTile].
abstract final class CareVisuals {
  static const IconData medicationIcon = CareIcons.pill;
  static const IconData measurementIcon = CareIcons.heartbeat;
  static const IconData appointmentIcon = ScheduleIcons.calendar;

  static const Color medicationTile = AppSettingsTileColors.doses;
  static const Color measurementTile = AppSettingsTileColors.measurements;
  static const Color appointmentTile = AppSettingsTileColors.appointments;
}
