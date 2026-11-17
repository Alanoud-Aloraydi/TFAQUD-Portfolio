import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The days of a booking under «أيام المواعيد», one chip each (a chip takes
/// its day off while another is left), then «إضافة يوم» and a line saying
/// each day is its own visit: so one day already reads as one of many.
class AppointmentDaysChips extends StatelessWidget {
  const AppointmentDaysChips({
    super.key,
    required this.dates,
    required this.onChanged,
    required this.onAdd,
  });

  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => InsetBlock(
    semanticLabel: context.tr('appointments.more_dates'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final DateTime day in dates)
              InputChip(
                label: Text(appointmentDate(context, day)),
                onDeleted: dates.length < 2
                    ? null
                    : () => onChanged(<DateTime>[
                        for (final DateTime d in dates)
                          if (d != day) d,
                      ]),
                deleteButtonTooltipMessage: context.tr(
                  'appointments.remove_date',
                ),
              ),
            ActionChip(
              avatar: const Icon(AppIcons.plus),
              label: Text(context.tr('appointments.add_day')),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('appointments.days_note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
