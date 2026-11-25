import 'dart:async';

import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/minutes_sheet.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/domain/entities/appointment_reminder_lead.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «تذكير قبل الموعد» in «إضافة موعد»: how long before the visit its own
/// reminder comes, chosen on the ruler of «ذكّرني لاحقًا» (5 minutes up to
/// 6 hours), which says the time it means for a visit at [time]. The
/// day-before reminder is fixed besides it and is not asked about here.
class AppointmentLeadRow extends StatelessWidget {
  const AppointmentLeadRow({
    super.key,
    required this.minutes,
    required this.time,
    required this.onChanged,
  });

  final int minutes;
  final TimeOfDay time;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => InsetRow(
    label: context.tr('appointments.remind_before'),
    value: appointmentLeadText(context, minutes),
    showChevron: true,
    onTap: () => unawaited(_pick(context)),
  );

  Future<void> _pick(BuildContext context) async {
    final int? chosen = await showMinutesSheet(
      context,
      title: context.tr('appointments.remind_before'),
      minutes: minutes,
      min: minAppointmentLead,
      max: maxAppointmentLead,
      headline: (int lead) => appointmentLeadText(context, lead),
      // «الساعة 9:00 ص»: when the reminder comes for a visit at [time].
      subline: (int lead) => context.tr(
        'reminders.snooze_at',
        args: <String>[
          timeOfDayText(
            TimeOfDay.fromDateTime(
              DateTime(
                2000,
                1,
                1,
                time.hour,
                time.minute,
              ).subtract(Duration(minutes: lead)),
            ),
          ),
        ],
      ),
    );
    if (chosen != null) onChanged(chosen);
  }
}

/// «قبل ساعة», «قبل 45 دقيقة», «قبل ساعة و30 دقيقة».
String appointmentLeadText(BuildContext context, int minutes) => context.tr(
  'appointments.lead_before',
  args: <String>[durationWords(context, minutes)],
);

/// Which appointments «السجل» shows: every one, the coming ones, or the
/// ones already behind.
enum AppointmentRecordFilter {
  all,
  upcoming,
  previous;

  /// Whether an appointment belongs in the list; [upcoming] is one still
  /// scheduled and not yet past.
  bool keeps({required bool isUpcoming}) => switch (this) {
    all => true,
    AppointmentRecordFilter.upcoming => isUpcoming,
    previous => !isUpcoming,
  };

  /// The appointments of [all] it keeps, newest first.
  List<CareAppointment> pick(List<CareAppointment> all, DateTime now) =>
      <CareAppointment>[
        for (final CareAppointment item in all)
          if (keeps(isUpcoming: isUpcomingAppointment(item, now))) item,
      ]..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  /// The key of its words, under `appointments.filters`.
  String get labelKey => 'appointments.filters.$name';
}
