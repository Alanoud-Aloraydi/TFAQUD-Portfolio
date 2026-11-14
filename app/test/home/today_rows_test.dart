import 'package:app/core/errors/failure.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_today_row.dart';
import 'package:app/features/home/presentation/widgets/next_task_card.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_row.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/widget_harness.dart';

/// Records what the measurement row sends to the server.
class _Measurements extends Fake implements MeasurementsRepositoryDomain {
  final List<MeasurementReadingDraft> drafts = <MeasurementReadingDraft>[];

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Stream<String> get recorded => const Stream<String>.empty();

  @override
  Future<List<MeasurementOccurrence>> occurrences(
    String circleId,
    DateTime from,
    DateTime to,
  ) async => const <MeasurementOccurrence>[];

  @override
  Future<MeasurementReading> record(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) async {
    drafts.add(draft);
    return MeasurementReading(
      id: 'r-1',
      kind: draft.kind,
      outcome: draft.outcome,
      recordedAt: noonInRiyadh,
    );
  }
}

/// Records what the dose controls send to the server.
class _Doses extends Fake implements MedicationsRepositoryDomain {
  _Doses(this.dose);

  final DoseOccurrence dose;
  final List<DoseRecordDraft> drafts = <DoseRecordDraft>[];

  @override
  Future<Result<List<DoseOccurrence>, Failure>> getOccurrences(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async => Success(<DoseOccurrence>[dose]);

  @override
  Future<Result<DoseRecord, Failure>> recordDose(
    String circleId,
    DoseOccurrence occurrence,
    DoseRecordDraft record,
  ) async {
    drafts.add(record);
    return Success(
      DoseRecord(id: 'd-1', outcome: record.outcome, recordedAt: noonInRiyadh),
    );
  }
}

MeasurementOccurrence _measurement(String time) => MeasurementOccurrence(
  planId: 'm-1',
  versionId: 'v-1',
  kind: MeasurementKind.glucose,
  scheduledOn: DateTime(2026, 11, 9),
  time: time,
  deadlineAt: DateTime.utc(2026, 11, 9, 12),
  status: MeasurementStatus.upcoming,
);

DoseOccurrence _dose(DateTime day) => DoseOccurrence(
  planId: 'p-1',
  scheduleId: 's-1',
  scheduledOn: day,
  time: '12:00',
  name: 'ميتفورمين',
  strengthValue: 500,
  strengthUnit: StrengthUnit.milligram,
  dosageForm: DosageForm.tablet,
  doseValue: 1,
  doseUnit: DoseUnit.tablet,
);

void main() {
  setUpAll(initTestLocalization);

  group('measurement row of «اليوم»', () {
    Future<_Measurements> show(
      WidgetTester tester,
      MeasurementOccurrence task,
    ) async {
      final _Measurements repository = _Measurements();
      final MeasurementTasksCubit cubit = MeasurementTasksCubit(
        MeasurementsUseCase(repository),
      );
      addTearDown(cubit.close);
      await cubit.load('c-1', DateTime(2026, 11, 9));
      await pumpArabic(
        tester,
        home: Scaffold(
          body: BlocProvider<MeasurementTasksCubit>.value(
            value: cubit,
            // [now] is the patient's wall time: noon in Riyadh.
            child: MeasurementTaskRow(
              task: task,
              now: DateTime.utc(2026, 11, 9, 12),
              circleId: 'c-1',
            ),
          ),
        ),
      );
      return repository;
    }

    testWidgets('offers its answers from an hour before, and skips', (
      tester,
    ) async {
      final _Measurements repository = await show(
        tester,
        _measurement('12:30'),
      );

      expect(find.text('measurements.record_reading'.tr()), findsOneWidget);
      await tester.tap(find.text('measurements.skip'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('measurements.skip_confirm'.tr()));
      await tester.pumpAndSettle();

      expect(repository.drafts.single.outcome, 'skipped');
    });

    testWidgets('offers nothing more than an hour before its time', (
      tester,
    ) async {
      await show(tester, _measurement('13:30'));

      expect(find.text('measurements.record_reading'.tr()), findsNothing);
      expect(find.text('measurements.skip'.tr()), findsNothing);
      expect(find.text('today_dashboard.status.upcoming'.tr()), findsOneWidget);
    });
  });

  group('unified rows of «اليوم»', () {
    CareAppointment appointment(String time) => CareAppointment(
      id: 'a-$time',
      specialty: 'عيادة السكري',
      kind: AppointmentKind.followUp,
      otherKind: null,
      scheduledOn: DateTime(2026, 11, 9),
      time: time,
      place: 'clinic',
      remoteMethod: null,
      companions: const <AppointmentCompanion>[],
      status: AppointmentStatus.scheduled,
      updatedAt: noonInRiyadh,
    );

    testWidgets('appointment uses the same upcoming wording', (tester) async {
      await pumpArabic(
        tester,
        home: Scaffold(body: AppointmentTodayRow(value: appointment('14:00'))),
      );

      expect(find.text('today_dashboard.status.upcoming'.tr()), findsOneWidget);
    });

    testWidgets('the row is plain without a circle to open it in', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: Scaffold(body: AppointmentTodayRow(value: appointment('14:00'))),
      );

      expect(
        find.descendant(
          of: find.byType(AppointmentTodayRow),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
      final InkWell area = tester.widget(find.byType(InkWell));
      expect(area.onTap, isNull);
    });

    testWidgets('a passed appointment asks for attendance confirmation', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: Scaffold(body: AppointmentTodayRow(value: appointment('10:00'))),
      );

      expect(
        find.text('today_dashboard.status.appointment_waiting'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('the large card names a measurement, never a dose', (
      tester,
    ) async {
      final measurement = _measurement('14:00');
      await pumpArabic(
        tester,
        home: Scaffold(
          body: NextTaskCard(
            task: (
              at: DateTime(2026, 11, 9, 14),
              medication: null,
              measurement: measurement,
              appointment: null,
            ),
            circleId: 'c-1',
            canManage: false,
            now: DateTime(2026, 11, 9, 12),
          ),
        ),
      );

      expect(
        find.text('today_dashboard.next_measurement'.tr()),
        findsOneWidget,
      );
      expect(find.text('today_dashboard.next_dose'.tr()), findsNothing);
    });
  });

  group('medication row of «اليوم»', () {
    Future<_Doses> show(WidgetTester tester, DoseOccurrence dose) async {
      final _Doses repository = _Doses(dose);
      final MedicationOccurrencesCubit cubit = MedicationOccurrencesCubit(
        MedicationsUseCase(repository),
        clock: () => noonInRiyadh,
      );
      addTearDown(cubit.close);
      await cubit.load('c-1', dose.scheduledOn, dose.scheduledOn);
      await pumpArabic(
        tester,
        home: Scaffold(
          body: BlocProvider<MedicationOccurrencesCubit>.value(
            value: cubit,
            child: DoseRecordControls(
              occurrence: dose,
              layout: DoseControlsLayout.today,
            ),
          ),
        ),
      );
      return repository;
    }

    testWidgets('«أخذتها» records the dose at the injected clock', (
      tester,
    ) async {
      final _Doses repository = await show(
        tester,
        _dose(DateTime(2026, 11, 9)),
      );

      await tester.tap(find.text('medications.taken_short'.tr()));
      await tester.pumpAndSettle();

      expect(repository.drafts.single.outcome, DoseOutcome.taken);
      expect(repository.drafts.single.takenAt, noonInRiyadh);
    });

    testWidgets('a dose of a later day offers no answer', (tester) async {
      await show(tester, _dose(DateTime(2026, 11, 10)));

      expect(find.text('medications.taken_short'.tr()), findsNothing);
      expect(find.text('medications.skip_short'.tr()), findsNothing);
    });
  });
}
