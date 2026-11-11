import 'dart:async';
import 'dart:typed_data';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/photo_probe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Appointments extends Fake implements AppointmentRepository {
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

class _Photos extends Fake implements PrivatePhotoRepository {
  int loads = 0;

  @override
  Future<Uint8List?> load(String path) async {
    loads++;
    return Uint8List(1);
  }
}

void main() {
  group('HomeQuietReload', () {
    test('a quiet load never shows the loading state', () async {
      final cubit = AppointmentsCubit(_Appointments());
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
      final cubit = AppointmentsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('circle-1');
      final states = <AppointmentsLoadStatus>[];
      final listening = cubit.stream.listen((s) => states.add(s.status));
      addTearDown(listening.cancel);

      final visit = CareAppointment(
        id: 'v-1',
        specialty: 'diabetes',
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
      final cubit = AppointmentsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('circle-1');
      expect(cubit.state.status, AppointmentsLoadStatus.failure);

      await cubit.load('circle-1', silent: true);

      // Nothing was shown to keep, so the error stays with its retry.
      expect(cubit.state.status, AppointmentsLoadStatus.failure);
    });

    testWidgets('PhotoProbe looks photos up once, not on every rebuild', (
      WidgetTester tester,
    ) async {
      final photos = _Photos();
      bool? shown;
      Widget app(List<String> ids) =>
          RepositoryProvider<PrivatePhotoRepository>.value(
            value: photos,
            child: PhotoProbe(
              circleId: 'c',
              planIds: ids,
              builder: (context, hasPhoto) {
                shown = hasPhoto;
                return const SizedBox();
              },
            ),
          );

      await tester.pumpWidget(app(['a', 'b']));
      await tester.pump();
      expect(photos.loads, 2);
      expect(shown, isTrue);

      await tester.pumpWidget(app(['a', 'b']));
      await tester.pump();
      expect(photos.loads, 2);

      await tester.pumpWidget(app(['a']));
      await tester.pump();
      expect(photos.loads, 3);
    });
  });
}
