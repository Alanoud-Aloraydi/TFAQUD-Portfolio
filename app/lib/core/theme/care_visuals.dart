import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/widgets.dart';

/// How each kind of care looks, the same in the detailed and the simplified
/// mode: medicines a pill on green, measurements a heartbeat on honey,
/// appointments a calendar on grey. Icons on these tiles use
/// [AppSemanticColors.onSettingsTile].
abstract final class CareVisuals {
  static const IconData medicationIcon = AppIcons.pill;
  static const IconData measurementIcon = AppIcons.heartbeat;
  static const IconData appointmentIcon = AppIcons.calendar;

  static const Color medicationTile = AppSemanticColors.settingsTileDoses;
  static const Color measurementTile =
      AppSemanticColors.settingsTileMeasurements;
  static const Color appointmentTile =
      AppSemanticColors.settingsTileAppointments;
}

/// How each kind of care on the phone's calendar looks: the icon and the
/// square behind it, as in [CareVisuals].
extension CalendarSyncLook on CalendarSyncCategory {
  /// The kind's icon.
  IconData get icon => switch (this) {
    CalendarSyncCategory.doses => CareVisuals.medicationIcon,
    CalendarSyncCategory.measurements => CareVisuals.measurementIcon,
    CalendarSyncCategory.appointments => CareVisuals.appointmentIcon,
  };

  /// The colour of the square behind the icon.
  Color get tile => switch (this) {
    CalendarSyncCategory.doses => CareVisuals.medicationTile,
    CalendarSyncCategory.measurements => CareVisuals.measurementTile,
    CalendarSyncCategory.appointments => CareVisuals.appointmentTile,
  };
}
