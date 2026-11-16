import 'dart:async';

import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The other dates of a booking: a clinic hands over a sheet of dates that
/// follow no rule, and each becomes its own visit with the same type, time
/// and place. Shown only when a visit is being added, never when one is
/// edited — an edit is that visit alone.
class AppointmentDatesRow extends StatelessWidget {
  const AppointmentDatesRow({
    super.key,
    required this.first,
    required this.dates,
    required this.onChanged,
  });

  /// The visit's own date, which cannot be chosen again.
  final DateTime first;

  /// The other dates, oldest first.
  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;

  /// How many visits the booking saves, the first one counted.
  int get _count => dates.length + 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      InsetRow(
        label: context.tr('appointments.more_dates'),
        value: dates.isEmpty
            ? context.tr('appointments.one_visit')
            : context.tr(
                'appointments.visits_count',
                args: <String>['$_count'],
              ),
        showChevron: true,
        onTap: () => unawaited(_add(context)),
      ),
      if (dates.isNotEmpty)
        InsetBlock(
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
                  deleteButtonTooltipMessage: context.tr(
                    'appointments.remove_date',
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  /// Asks for one more date, and keeps the list in order without repeats.
  Future<void> _add(BuildContext context) async {
    final DateTime? chosen = await showTafaqodDateSheet(
      context,
      title: context.tr('appointments.more_dates'),
      initialDate: (dates.lastOrNull ?? first).add(const Duration(days: 1)),
      firstDate: first.add(const Duration(days: 1)),
      lastDate: DateTime(first.year + 5, 12, 31),
    );
    if (chosen == null || chosen == first || dates.contains(chosen)) return;
    onChanged(<DateTime>[...dates, chosen]..sort());
  }
}
