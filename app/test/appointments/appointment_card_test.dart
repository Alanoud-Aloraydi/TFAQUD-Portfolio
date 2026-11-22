import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/buttons/stop_button.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// A visit of November 2026; the harness reads the cards at noon on the 9th.
CareAppointment _visit(
  String id,
  int day, {
  String? series = 's',
  AppointmentStatus status = AppointmentStatus.scheduled,
}) => CareAppointment(
  id: id,
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, day),
  time: '10:30',
  place: 'مستشفى الملك فهد',
  remoteMethod: null,
  companions: const <AppointmentCompanion>[],
  status: status,
  updatedAt: DateTime.utc(2026, 11, 1),
  seriesId: series,
);

/// A booking of four dates: two attended, two ahead.
final List<CareAppointment> _booking = <CareAppointment>[
  _visit('b1', 2, status: AppointmentStatus.completed),
  _visit('b2', 5, status: AppointmentStatus.completed),
  _visit('b3', 16),
  _visit('b4', 23),
];

Future<void> _open(
  WidgetTester tester,
  CareAppointment value, {
  List<CareAppointment> others = const <CareAppointment>[],
  List<CareAppointment> all = const <CareAppointment>[],
  bool editable = true,
}) async {
  await pumpArabic(
    tester,
    home: Scaffold(
      body: SingleChildScrollView(
        child: AppointmentCard(
          value: value,
          circleId: 'c-1',
          canManage: true,
          editable: editable,
          others: others,
          all: all,
        ),
      ),
    ),
  );
  await tester.tap(find.text('appointments.details'.tr()));
  await tester.pumpAndSettle();
}

Finder _button(String key) => find.widgetWithText(TextButton, key.tr());

String _place(int index, int count) =>
    'appointments.visit_of_series'.tr(args: <String>['$index', '$count']);

void main() {
  setUpAll(initTestLocalization);

  group('An appointment card', () {
    testWidgets('a booking is one card, its other dates in the details', (
      tester,
    ) async {
      await _open(
        tester,
        _booking[2],
        others: <CareAppointment>[_booking[0], _booking[1], _booking[3]],
        all: _booking,
      );

      expect(find.text(_place(3, 4)), findsOneWidget);
      expect(find.text('appointments.other_visits'.tr()), findsOneWidget);
      expect(find.text(_place(1, 4)), findsOneWidget);
      expect(find.text(_place(2, 4)), findsOneWidget);
      expect(find.text(_place(4, 4)), findsOneWidget);
      // The two attended dates each keep their sheet.
      expect(find.text('appointments.visit_title'.tr()), findsNWidgets(2));
      expect(find.byType(EditAction), findsOneWidget);
      expect(find.text('appointments.cancel_appointment'.tr()), findsOneWidget);
    });

    testWidgets('a visit on its own has no «المواعيد الأخرى»', (tester) async {
      final CareAppointment alone = _visit('a', 16, series: null);
      await _open(tester, alone, all: <CareAppointment>[alone]);

      expect(find.text('appointments.other_visits'.tr()), findsNothing);
      expect(find.text(_place(1, 1)), findsNothing);
    });

    testWidgets('in «السجل» only the sheet is left to change', (tester) async {
      final CareAppointment passed = _visit('b2', 8);
      final List<CareAppointment> all = <CareAppointment>[_booking[0], passed];
      await _open(
        tester,
        passed,
        others: <CareAppointment>[_booking[0]],
        all: all,
        editable: false,
      );

      expect(find.byType(EditAction), findsNothing);
      // «حضرت» is still the status of the attended date in the details,
      // but no longer a button.
      expect(_button('appointments.mark_completed'), findsNothing);
      expect(find.text('appointments.cancel_appointment'.tr()), findsNothing);
      expect(find.text('appointments.visit_title'.tr()), findsOneWidget);
    });

    testWidgets('the same card in «الخطة» is edited or cancelled, and «حضرت» '
        'is answered in «اليوم» alone', (tester) async {
      final CareAppointment passed = _visit('b2', 8, series: null);
      await _open(tester, passed, all: <CareAppointment>[passed]);

      expect(find.byType(EditAction), findsOneWidget);
      expect(_button('appointments.mark_completed'), findsNothing);
      expect(find.text('appointments.cancel_appointment'.tr()), findsOneWidget);
    });

    testWidgets('a visit that left «يحتاج انتباهك» unanswered is missed', (
      tester,
    ) async {
      // The 6th is three days before the 9th: past the two days «اليوم»
      // keeps, so it asks nothing more.
      final CareAppointment missed = _visit('m', 6, series: null);
      await _open(tester, missed, all: <CareAppointment>[missed]);

      expect(find.text('appointments.status.missed'.tr()), findsOneWidget);
      expect(_button('appointments.mark_completed'), findsNothing);
      expect(find.text('appointments.cancel_appointment'.tr()), findsNothing);
    });

    testWidgets('its details name the one person who added it, and its '
        'cancel has the stop of a medicine', (tester) async {
      final CareAppointment added = CareAppointment(
        id: 'a',
        kind: AppointmentKind.followUp,
        otherKind: null,
        scheduledOn: DateTime(2026, 11, 16),
        time: '10:30',
        place: 'مستشفى الملك فهد',
        remoteMethod: null,
        companions: const <AppointmentCompanion>[],
        status: AppointmentStatus.scheduled,
        updatedAt: DateTime.utc(2026, 11, 1),
        createdByName: 'لينا',
        updatedByName: 'سارة',
      );
      await _open(tester, added, all: <CareAppointment>[added]);

      expect(find.text('appointments.added_by'.tr()), findsOneWidget);
      expect(find.text('لينا'), findsOneWidget);
      expect(find.text('سارة'), findsNothing);
      expect(find.text('plan_details.people'.tr()), findsNothing);
      final StopButton stop = tester.widget(find.byType(StopButton));
      expect(stop.icon, const StopButton(label: '', onPressed: null).icon);
    });

    testWidgets('in «السجل» the badge of a past visit opens how it went, '
        'its own ticked', (tester) async {
      final CareAppointment missed = _visit('m', 6, series: null);
      await _open(
        tester,
        missed,
        all: <CareAppointment>[missed],
        editable: false,
      );

      await tester.tap(find.text('appointments.status.missed'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('appointments.status.completed'.tr()), findsOneWidget);
      expect(find.text('appointments.status.cancelled'.tr()), findsOneWidget);
    });

    testWidgets('«حضرت» with something in «ورقة الزيارة» stays, and says '
        'why', (tester) async {
      final CareAppointment written = CareAppointment(
        id: 'w',
        kind: AppointmentKind.followUp,
        otherKind: null,
        scheduledOn: DateTime(2026, 11, 8),
        time: '10:30',
        place: 'مستشفى الملك فهد',
        remoteMethod: null,
        companions: const <AppointmentCompanion>[],
        status: AppointmentStatus.completed,
        updatedAt: DateTime.utc(2026, 11, 8),
        visitFilled: true,
      );
      await _open(
        tester,
        written,
        all: <CareAppointment>[written],
        editable: false,
      );

      await tester.tap(find.text('appointments.status.completed'.tr()));
      await tester.pump();

      expect(find.text('appointments.outcome_locked'.tr()), findsOneWidget);
      expect(find.text('appointments.status.missed'.tr()), findsNothing);
    });
  });
}
