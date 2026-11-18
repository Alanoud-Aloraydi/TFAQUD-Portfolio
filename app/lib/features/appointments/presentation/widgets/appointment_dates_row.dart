import 'dart:async';

import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/features/appointments/domain/appointment_days.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_days_chips.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The days of a booking, each its own visit with the same type, time and
/// place. The row is the main visit's day (the first), and a tap changes
/// it; «إضافة يوم» under it adds another, and a chip takes a day off while
/// another is left (the next one becomes the main). While a visit is
/// edited ([single]) the row is its one day.
class AppointmentDatesRow extends StatelessWidget {
  const AppointmentDatesRow({
    super.key,
    required this.dates,
    required this.onChanged,
    this.single = false,
  });

  /// The main day first, then the added ones, oldest first.
  final List<DateTime> dates;
  final ValueChanged<List<DateTime>> onChanged;
  final bool single;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      InsetRow(
        label: context.tr('appointments.main_day'),
        value: dates.isEmpty ? null : appointmentDate(context, dates.first),
        placeholder: context.tr('appointments.pick_day'),
        showChevron: true,
        onTap: () => unawaited(_pick(context, main: true)),
      ),
      if (!single)
        AppointmentDaysChips(
          dates: dates,
          onChanged: onChanged,
          onAdd: () => unawaited(_pick(context, main: false)),
        ),
    ],
  );

  /// The main day ([main]) or another one, from the patient's today.
  Future<void> _pick(BuildContext context, {required bool main}) async {
    final DateTime today = PatientClockScope.of(context).today();
    final DateTime? at = main ? dates.firstOrNull : dayAfterLast(dates);
    final DateTime? chosen = await showTafaqodDateSheet(
      context,
      title: context.tr(
        main ? 'appointments.main_day' : 'appointments.add_day',
      ),
      initialDate: at == null || at.isBefore(today) ? today : at,
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (chosen == null) return;
    onChanged(main ? withMainDay(dates, chosen) : withAddedDay(dates, chosen));
  }
}
