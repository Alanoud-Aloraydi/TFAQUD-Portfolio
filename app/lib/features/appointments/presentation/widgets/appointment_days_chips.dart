import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The days of a booking under «أيام المواعيد», each in a chip that takes
/// it off.
class AppointmentDaysChips extends StatelessWidget {
  const AppointmentDaysChips({
    super.key,
    required this.dates,
    required this.onChanged,
  });

  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;

  @override
  Widget build(BuildContext context) => InsetBlock(
    semanticLabel: context.tr('appointments.more_dates'),
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final DateTime day in dates)
          InputChip(
            label: Text(appointmentDate(context, day)),
            onDeleted: () => onChanged(<DateTime>[
              for (final DateTime d in dates)
                if (d != day) d,
            ]),
            deleteButtonTooltipMessage: context.tr('appointments.remove_date'),
          ),
      ],
    ),
  );
}
