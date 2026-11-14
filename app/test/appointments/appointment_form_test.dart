import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository_domain.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/widget_harness.dart';

const AppointmentCompanion _nora = AppointmentCompanion(
  id: 'a-1',
  name: 'نورة',
);

/// One companion to choose; remembers the appointments the form saves.
class _Appointments extends Fake implements AppointmentsRepositoryDomain {
  final List<AppointmentDraft> created = <AppointmentDraft>[];

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<CareAppointment>> appointments(String circleId) async =>
      const <CareAppointment>[];

  @override
  Future<List<AppointmentCompanion>> companions(String circleId) async =>
      const <AppointmentCompanion>[_nora];

  @override
  Future<CareAppointment> create(
    String circleId,
    AppointmentDraft draft,
  ) async {
    created.add(draft);
    return AppointmentModel.tryFromJson(<String, dynamic>{
      'id': 'v-1',
      'specialty': draft.specialty,
      'kind': 'follow_up',
      'other_text': null,
      'scheduled_on': '2026-11-09',
      'time_of_day': draft.time,
      'place': draft.place,
      'remote_method': null,
      'companions': <dynamic>[],
      'status': 'scheduled',
      'updated_at': '2026-11-09T00:00:00Z',
    })!;
  }
}

/// The patient's clock at [hour]:00 in Riyadh on 9 November 2026.
PatientClock _riyadhAt(int hour) => PatientClock(
  'Asia/Riyadh',
  clock: () => DateTime.utc(2026, 11, 9, hour - 3),
);

void main() {
  group('AppointmentForm', () {
    setUpAll(initTestLocalization);

    /// The form for a new visit, opened over a home page.
    Future<_Appointments> open(WidgetTester tester, PatientClock clock) async {
      final _Appointments repository = _Appointments();
      final AppointmentsCubit appointments = AppointmentsCubit(
        AppointmentsUseCase(repository),
      );
      final AppointmentCompanionsCubit companions = AppointmentCompanionsCubit(
        AppointmentsUseCase(repository),
      );
      addTearDown(appointments.close);
      addTearDown(companions.close);
      await appointments.load('c-1');
      await companions.load('c-1');
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (context, state) => const Text('home')),
          GoRoute(
            path: '/form',
            builder: (context, state) => MultiBlocProvider(
              providers: <BlocProvider<dynamic>>[
                BlocProvider<AppointmentsCubit>.value(value: appointments),
                BlocProvider<AppointmentCompanionsCubit>.value(
                  value: companions,
                ),
              ],
              child: const AppointmentFormPage(circleId: 'c-1'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await pumpArabic(tester, router: router, clock: clock);
      unawaited(router.push<bool>('/form'));
      await tester.pumpAndSettle();
      return repository;
    }

    /// Scrolls the form's list until [finder] is built and on screen: the
    /// list builds only the rows near the screen.
    Future<void> scrollTo(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );

    /// The place field, below the clinic field in the form.
    Finder placeField() =>
        find.widgetWithText(TextField, 'appointments.place'.tr());

    /// Taps a companion chip, which grows a check mark and pushes the row
    /// down, so it is brought back on screen before every tap.
    Future<void> tapCompanion(WidgetTester tester) async {
      await scrollTo(tester, find.text('نورة'));
      await tester.ensureVisible(find.text('نورة'));
      await tester.pump();
      await tester.tap(find.text('نورة'));
      await tester.pump();
    }

    Future<void> fillAndSave(WidgetTester tester) async {
      await tapCompanion(tester);
      await tester.enterText(placeField(), 'الحبيب');
      await tester.tap(find.text('appointments.save'.tr()));
      await tester.pumpAndSettle();
    }

    testWidgets('a visit with no companion is saved: going is optional', (
      tester,
    ) async {
      final _Appointments repository = await open(tester, _riyadhAt(8));
      // Nobody chosen; the place is above the companions.
      await scrollTo(tester, find.text('نورة'));

      await tester.enterText(placeField(), 'الحبيب');
      await tester.tap(find.text('appointments.save'.tr()));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      expect(repository.created.single.companionAccountIds, isEmpty);
    });

    testWidgets('the last companion can be taken off again', (tester) async {
      final _Appointments repository = await open(tester, _riyadhAt(8));
      await tapCompanion(tester);
      await tapCompanion(tester);

      await tester.enterText(placeField(), 'الحبيب');
      await tester.tap(find.text('appointments.save'.tr()));
      await tester.pumpAndSettle();

      expect(repository.created.single.companionAccountIds, isEmpty);
    });

    testWidgets('the kind and the clinic are saved; the clinic is optional', (
      tester,
    ) async {
      final _Appointments repository = await open(tester, _riyadhAt(8));

      // A kind from another group than the first.
      await scrollTo(tester, find.text('appointments.kinds.vaccine'.tr()));
      await tester.tap(find.text('appointments.kinds.vaccine'.tr()));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'appointments.clinic_field'.tr()),
        'عيادة السكري',
      );
      await fillAndSave(tester);

      final AppointmentDraft first = repository.created.single;
      expect(first.kind, AppointmentKind.vaccine);
      expect(first.specialty, 'عيادة السكري');
    });

    testWidgets('a visit saves with no clinic at all', (tester) async {
      final _Appointments repository = await open(tester, _riyadhAt(8));

      await fillAndSave(tester);

      expect(repository.created.single.specialty, isNull);
      expect(repository.created.single.kind, AppointmentKind.followUp);
    });

    testWidgets('the note says who gets the reminder', (tester) async {
      await open(tester, _riyadhAt(8));

      await scrollTo(tester, find.text('appointments.companion_hint'.tr()));

      expect(find.text('appointments.companion_hint'.tr()), findsOneWidget);
    });

    testWidgets(
      'today at 10:00 is in the past once the patient is past 10:00',
      (tester) async {
        final _Appointments repository = await open(tester, _riyadhAt(12));

        await fillAndSave(tester);
        await scrollTo(tester, find.text('appointments.time_in_past'.tr()));

        expect(find.text('appointments.time_in_past'.tr()), findsOneWidget);
        expect(repository.created, isEmpty);
      },
    );

    testWidgets('the same visit is saved on the patient today before 10:00', (
      tester,
    ) async {
      final _Appointments repository = await open(tester, _riyadhAt(8));

      await fillAndSave(tester);

      final AppointmentDraft draft = repository.created.single;
      expect(draft.scheduledOn, DateTime(2026, 11, 9));
      expect(draft.time, '10:00');
      expect(draft.companionAccountIds, <String>['a-1']);
      expect(find.text('home'), findsOneWidget);
    });
  });
}
