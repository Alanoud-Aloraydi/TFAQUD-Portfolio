import 'dart:async';

import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:flutter_test/flutter_test.dart';

class _Appointments extends Fake implements AppointmentsRepository {
  final StreamController<String> changed = StreamController<String>.broadcast();

  /// When true, every read fails as offline.
  bool offline = false;

  /// What a read returns; a test changes it to save a visit "elsewhere".
  List<CareAppointment> saved = const <CareAppointment>[];

  @override
  Stream<String> get changes => changed.stream;

  @override
  Future<List<CareAppointment>> appointments(String circleId) async {
    if (offline) throw Exception('offline');
    return saved;
  }
}

void main() {
  group('HomeQuietReload', () {
    test('a quiet load never shows the loading state', () async {
      final cubit = AppointmentsCubit(AppointmentsUseCase(_Appointments()));
      addTearDown(cubit.close);
      await cubit.load('circle-1');
      final states = <AppointmentsLoadStatus>[];
      final listening = cubit.stream.listen((s) => states.add(s.status));
      addTearDown(listening.cancel);

      await cubit.load('circle-1', silent: true);
      expect(states, isNot(contains(AppointmentsLoadStatus.loading)));

      // Another circle is a different list: it starts from loading.
      await cubit.load('circle-2', silent: true);
      expect(states, contains(AppointmentsLoadStatus.loading));
    });

    test('a change saved elsewhere reads the list again quietly', () async {
      final repository = _Appointments();
      final cubit = AppointmentsCubit(AppointmentsUseCase(repository));
      addTearDown(cubit.close);
      await cubit.load('circle-1');
      final states = <AppointmentsLoadStatus>[];
      final listening = cubit.stream.listen((s) => states.add(s.status));
      addTearDown(listening.cancel);

      final visit = CareAppointment(
        id: 'v-1',
        specialty: 'عيادة السكري',
        kind: AppointmentKind.followUp,
        otherKind: null,
        scheduledOn: DateTime(2026, 11, 10),
        time: '10:00',
        place: 'clinic',
        remoteMethod: null,
        companions: const <AppointmentCompanion>[],
        status: AppointmentStatus.scheduled,
        updatedAt: DateTime.utc(2026, 11, 9),
      );
      repository.saved = <CareAppointment>[visit];
      repository.changed.add('circle-1');
      await pumpEventQueue();

      // No loading in between: the new list replaces the shown one.
      expect(states, [AppointmentsLoadStatus.ready]);
      expect(cubit.state.appointments, <CareAppointment>[visit]);
    });

    test('a quiet load after a failure still shows the failure', () async {
      final repository = _Appointments()..offline = true;
      final cubit = AppointmentsCubit(AppointmentsUseCase(repository));
      addTearDown(cubit.close);
      await cubit.load('circle-1');
      expect(cubit.state.status, AppointmentsLoadStatus.failure);

      await cubit.load('circle-1', silent: true);

      // Nothing was shown to keep, so the error stays with its retry.
      expect(cubit.state.status, AppointmentsLoadStatus.failure);
    });
  });
}
