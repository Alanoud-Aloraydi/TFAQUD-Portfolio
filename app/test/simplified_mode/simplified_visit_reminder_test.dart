import 'package:app/app/router/routers.dart';
import 'package:app/app/services/reminders/dose_reminders.dart' show TaskSnooze;
import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_reminder_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/widget_harness.dart';

/// A follow-up at [time] on 9 November 2026, with Lina coming along.
CareAppointment _visit(String time) => CareAppointment(
  id: 'v-$time',
  specialty: 'عيادة السكري',
  kind: AppointmentKind.followUp,
  otherKind: null,
  scheduledOn: DateTime(2026, 11, 9),
  time: time,
  place: null,
  remoteMethod: null,
  companions: const <AppointmentCompanion>[
    AppointmentCompanion(id: 'lina', name: 'لينا', avatarCode: 'w1_1'),
  ],
  status: AppointmentStatus.scheduled,
  updatedAt: noonInRiyadh,
);

/// A day of two visits, and the ones the patient said «حضرت» for.
class _UseCase implements SimplifiedModeUseCase {
  _UseCase(this.visits);

  final List<CareAppointment> visits;
  final List<CareAppointment> attended = <CareAppointment>[];
  final ValueNotifier<Map<String, TaskSnooze>> _snoozes =
      ValueNotifier<Map<String, TaskSnooze>>(const <String, TaskSnooze>{});

  @override
  Future<Result<SimplifiedDay, Failure>> loadDay(DateTime now) async => Success(
    SimplifiedDay(
      circleId: 'c-1',
      circleName: 'دائرتي',
      accountId: 'a-1',
      isPatient: true,
      displayName: 'مريم',
      timeZone: 'Asia/Riyadh',
      doses: const [],
      measurements: const <MeasurementOccurrence>[],
      appointments: visits,
      family: const [],
      reasons: const <String, String>{},
    ),
  );

  @override
  Future<Result<CareAppointment, Failure>> attendAppointment(
    String circleId,
    CareAppointment visit,
  ) async {
    attended.add(visit);
    return Success(visit);
  }

  @override
  Future<void> keepReminding(SimplifiedDay day) async {}

  @override
  ValueListenable<Map<String, TaskSnooze>> get snoozes => _snoozes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('A visit\'s full-screen reminder', () {
    setUpAll(initTestLocalization);

    late SimplifiedModeCubit cubit;

    /// The reminder of the visit at [time], at the patient's noon, with
    /// the done page writing what it was told.
    Future<(_UseCase, ValueNotifier<Object?>)> open(
      WidgetTester tester,
      String time,
    ) async {
      final _UseCase useCase = _UseCase(<CareAppointment>[
        _visit('11:30'),
        _visit('16:00'),
      ]);
      final ValueNotifier<Object?> done = ValueNotifier<Object?>(null);
      cubit = SimplifiedModeCubit(useCase, clock: () => noonInRiyadh);
      await cubit.load();
      final GoRouter router = GoRouter(
        initialLocation: Routes.simplifiedReminder,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.simplifiedReminder,
            builder: (context, state) => BlocProvider.value(
              value: cubit,
              child: SimplifiedReminderScreen(
                request: ReminderRequest(
                  TodayTaskKind.appointment,
                  taskKey: appointmentItemKey('c-1', 'v-$time'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.simplifiedDone,
            builder: (context, state) {
              done.value = state.extra;
              return const Text('done page');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await pumpArabic(tester, router: router);
      return (useCase, done);
    }

    Finder answer(String label) => find.descendant(
      of: find.byWidgetPredicate(
        (Widget widget) =>
            widget is Semantics && widget.properties.label == spoken(label),
      ),
      matching: find.text(label),
    );

    testWidgets('a visit whose time came is answered with «حضرت», and '
        'says so after', (tester) async {
      final (_UseCase useCase, ValueNotifier<Object?> done) = await open(
        tester,
        '11:30',
      );
      final Finder attend = answer('appointments.mark_completed'.tr());
      expect(attend, findsOneWidget);

      await tester.ensureVisible(attend);
      await tester.tap(attend);
      await tester.pumpAndSettle();

      expect(useCase.attended.single.id, 'v-11:30');
      expect(done.value, isA<SimplifiedDoneVisitAttended>());
      expect(find.text('done page'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('a visit later today is only read, «تمام، فهمت»', (
      tester,
    ) async {
      final (_UseCase useCase, _) = await open(tester, '16:00');

      expect(answer('appointments.mark_completed'.tr()), findsNothing);
      expect(answer('simplified_mode.got_it'.tr()), findsOneWidget);
      expect(useCase.attended, isEmpty);
      await cubit.close();
    });

    testWidgets('who comes along is shown by name, after their photo', (
      tester,
    ) async {
      await open(tester, '11:30');

      expect(find.text('لينا'), findsOneWidget);
      expect(find.byType(PersonPhoto), findsOneWidget);
      // Not the words alone, «معك: لينا», as it was.
      expect(find.text('معك: لينا'), findsNothing);
      await cubit.close();
    });
  });
}
