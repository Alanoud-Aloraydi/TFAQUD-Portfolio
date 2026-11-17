import 'dart:async';

import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_days_chips.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «أيام المواعيد»: every day of a booking, each its own visit with the
/// same type, time and place; the row or «إضافة يوم» adds one. While a
/// visit is edited ([single]) the row is its one day, and a tap moves it.
class AppointmentDatesRow extends StatelessWidget {
  const AppointmentDatesRow({
    super.key,
    required this.dates,
    required this.onChanged,
    this.single = false,
  });

  /// The days, oldest first.
  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;
  final bool single;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      InsetRow(
        label: context.tr('appointments.more_dates'),
        value: switch (dates) {
          [] => null,
          [final DateTime day] => appointmentDate(context, day),
          _ => context.tr(
            'appointments.visits_count',
            args: <String>['${dates.length}'],
          ),
        },
        placeholder: context.tr('appointments.pick_days'),
        showChevron: true,
        onTap: () => unawaited(_pick(context)),
      ),
      if (!single)
        AppointmentDaysChips(
          dates: dates,
          onChanged: onChanged,
          onAdd: () => unawaited(_pick(context)),
        ),
    ],
  );

  Future<void> _pick(BuildContext context) async {
    final DateTime today = PatientClockScope.of(context).today();
    final DateTime? last = dates.lastOrNull;
    final DateTime? chosen = await showTafaqodDateSheet(
      context,
      title: context.tr('appointments.more_dates'),
      initialDate: single
          ? (last == null || last.isBefore(today) ? today : last)
          : (last == null ? today : last.add(const Duration(days: 1))),
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (chosen == null || (!single && dates.contains(chosen))) return;
    final List<DateTime> kept = single ? <DateTime>[] : dates;
    onChanged(<DateTime>[...kept, chosen]..sort());
  }
}
