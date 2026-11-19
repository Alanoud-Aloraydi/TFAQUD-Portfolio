import 'package:app/features/appointments/presentation/widgets/appointment_record_empty.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_list.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Future<void> _pumpMedicines(WidgetTester tester, {required bool canAdd}) =>
    pumpArabic(
      tester,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ListView(
            children: medicationRecordList(
              context,
              circleId: 'circle-1',
              plans: const <MedicationPlan>[],
              canAdd: canAdd,
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(initTestLocalization);

  group('«السجل» with nothing in it', () {
    testWidgets('medicines offer «جدولة دواء» as «الخطة» does', (
      WidgetTester tester,
    ) async {
      await _pumpMedicines(tester, canAdd: true);

      expect(find.text('medications.no_records'.tr()), findsOneWidget);
      expect(find.text('add.medication'.tr()), findsOneWidget);
    });

    testWidgets('medicines offer nothing to someone who cannot add', (
      WidgetTester tester,
    ) async {
      await _pumpMedicines(tester, canAdd: false);

      expect(find.text('add.medication'.tr()), findsNothing);
    });

    testWidgets('visits offer «إضافة موعد طبي» only when they may', (
      WidgetTester tester,
    ) async {
      await pumpArabic(
        tester,
        home: const Scaffold(
          body: AppointmentRecordEmpty(circleId: 'circle-1', canAdd: true),
        ),
      );
      expect(find.text('appointments.no_records'.tr()), findsOneWidget);
      expect(find.text('add.appointment'.tr()), findsOneWidget);

      await pumpArabic(
        tester,
        home: const Scaffold(
          body: AppointmentRecordEmpty(circleId: 'circle-1', canAdd: false),
        ),
      );
      expect(find.text('add.appointment'.tr()), findsNothing);
    });
  });
}
