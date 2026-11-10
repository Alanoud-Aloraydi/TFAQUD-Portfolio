import 'dart:async';

import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  String id = 'a1',
  String kind = 'follow_up',
  String status = 'scheduled',
}) => <String, dynamic>{
  'id': id,
  'specialty': 'diabetes',
  'kind': kind,
  'other_kind': null,
  'scheduled_on': '2030-01-05',
  'time_of_day': '10:00',
  'place': 'Clinic',
  'remote_method': null,
  'companions': <dynamic>[],
  'status': status,
  'updated_at': '2030-01-01T00:00:00Z',
};

AppointmentDraft _draft() => AppointmentDraft(
  specialty: 'diabetes',
  kind: AppointmentKind.test,
  otherKind: null,
  scheduledOn: DateTime(2030, 1, 5),
  time: '10:00',
  place: 'Clinic',
  remoteMethod: null,
  companionAccountIds: const <String>['u1'],
);

class _FakeRepository implements AppointmentRepository {
  final StreamController<String> _changes = StreamController<String>.broadcast(
    sync: true,
  );
  final List<String> loaded = <String>[];
  Completer<CareAppointment>? pendingWrite;
  Object? writeError;

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<List<CareAppointment>> appointments(String circleId) async {
    loaded.add(circleId);
    return <CareAppointment>[];
  }

  @override
  Future<CareAppointment> create(String circleId, AppointmentDraft draft) {
    if (writeError != null) return Future<CareAppointment>.error(writeError!);
    final CareAppointment saved = AppointmentModel.tryFromJson(_json())!;
    _changes.add(circleId);
    return Future<CareAppointment>.value(saved);
  }

  @override
  Future<CareAppointment> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) => pendingWrite!.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  group('AppointmentsCubit', () {
    test('an unknown kind reads as other and an unknown status is skipped', () {
      expect(
        AppointmentModel.tryFromJson(_json(kind: 'surgery'))!.kind,
        AppointmentKind.other,
      );
      expect(AppointmentModel.tryFromJson(_json(status: 'paused')), isNull);
      expect(
        AppointmentModel.tryFromJson(_json(kind: 'follow_up'))!.kind,
        AppointmentKind.followUp,
      );
    });

    test(
      'a saved change reloads the circle through the changes stream',
      () async {
        final _FakeRepository repository = _FakeRepository();
        final AppointmentsCubit cubit = AppointmentsCubit(repository);
        addTearDown(cubit.close);
        await cubit.load('c1');

        final String? errorKey = await cubit.create('c1', _draft());
        await Future<void>.delayed(Duration.zero);

        expect(errorKey, isNull);
        expect(repository.loaded, <String>['c1', 'c1']);
      },
    );

    test('a change of another circle does not reload this one', () async {
      final _FakeRepository repository = _FakeRepository();
      final AppointmentsCubit cubit = AppointmentsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('c1');

      repository._changes.add('c2');
      await Future<void>.delayed(Duration.zero);

      expect(repository.loaded, <String>['c1']);
    });

    test('a failed write returns its message key', () async {
      final _FakeRepository repository = _FakeRepository()
        ..writeError = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(),
            statusCode: 422,
            data: <String, dynamic>{
              'error': <String, dynamic>{'code': 'appointment_time_in_past'},
            },
          ),
        );
      final AppointmentsCubit cubit = AppointmentsCubit(repository);
      addTearDown(cubit.close);

      expect(await cubit.create('c1', _draft()), 'appointments.time_in_past');
    });

    test('a second write while one is sending is refused', () async {
      final _FakeRepository repository = _FakeRepository()
        ..pendingWrite = Completer<CareAppointment>();
      final AppointmentsCubit cubit = AppointmentsCubit(repository);
      addTearDown(cubit.close);
      final CareAppointment appointment = AppointmentModel.tryFromJson(
        _json(),
      )!;

      final Future<String?> first = cubit.setStatus(
        'c1',
        appointment,
        AppointmentStatus.cancelled,
      );
      final String? second = await cubit.setStatus(
        'c1',
        appointment,
        AppointmentStatus.cancelled,
      );
      repository.pendingWrite!.complete(appointment);

      expect(second, 'error.unknown');
      expect(await first, isNull);
    });
  });
}
