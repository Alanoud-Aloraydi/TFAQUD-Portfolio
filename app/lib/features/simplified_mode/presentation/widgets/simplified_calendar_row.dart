import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_switch_row.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_settings_tile_colors.dart';

/// The calendar row: a calendar square, what goes on the calendar, a switch.
class SimplifiedCalendarRow extends StatelessWidget {
  const SimplifiedCalendarRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SimplifiedSwitchRow(
    icon: ScheduleIcons.calendar,
    background: AppSettingsTileColors.appointments,
    label: label,
    value: value,
    onChanged: onChanged,
  );
}
