import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/reminder_plan.dart';
import 'package:app/core/localization/dose_reminder_texts.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

const ReminderCircle _circle = ReminderCircle(
  id: 'c-1',
  name: 'رعايتي',
  viewerId: 'a-1',
  viewerIsPatient: true,
  timeZone: 'Asia/Riyadh',
);

/// A visit reminded [lead] minutes before it.
CareAppointment _visit(int lead) => CareAppointment(
  id: 'v-1',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, 20),
  time: '10:00',
  place: 'مستشفى',
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: AppointmentStatus.scheduled,
  updatedAt: DateTime.utc(2026, 11, 1),
  reminderLeadMinutes: lead,
);

void main() {
  setUpAll(initTestLocalization);

  testWidgets('the near reminder of a visit says the lead chosen for it, '
      'not a fixed two hours', (tester) async {
    // The words are read once the translations are loaded.
    await pumpArabic(tester, home: const SizedBox());

    String soon(int lead) => doseReminderTexts.appointmentTitle(
      _circle,
      AppointmentLead.soon,
      _visit(lead),
    );

    expect(
      soon(45),
      'reminders.appointment_soon'.tr(args: <String>[afterMinutesText(45)]),
    );
    expect(soon(45), contains('45'));
    expect(soon(90), isNot(contains('ساعتين')));
    expect(soon(120), contains('ساعتين'));
    expect(
      afterMinutesText(60),
      'today_dashboard.after'.tr(
        args: <String>[
          'counts.hours.one'.tr(args: <String>['1']),
        ],
      ),
    );
  });
}
