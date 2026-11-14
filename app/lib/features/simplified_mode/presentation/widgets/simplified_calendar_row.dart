import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/task_visuals.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Row(
          children: <Widget>[
            const CareIconTile(
              icon: AppIcons.calendar,
              background: AppSemanticColors.settingsTileAppointments,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: SimplifiedStyle.label(SimplifiedStyle.body),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: SimplifiedStyle.success,
            ),
          ],
        ),
      ),
    );
  }
}
