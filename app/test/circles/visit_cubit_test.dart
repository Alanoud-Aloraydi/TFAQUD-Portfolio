import 'dart:async';

import 'package:app/features/appointments/data/visit_audio_service.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A recorder whose permission answer the test releases by hand.
class _FakeAudio implements VisitAudioService {
  final Completer<bool> permission = Completer<bool>();
  int disposed = 0;
  int starts = 0;

  @override
  Future<bool> start() {
    starts++;
    return permission.future;
  }

  @override
  Future<void> dispose() async => disposed++;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeRepository implements VisitRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  group('VisitCubit', () {
    test('a cubit closed during the permission prompt does not emit', () async {
      final _FakeAudio audio = _FakeAudio();
      final VisitCubit cubit = VisitCubit(
        _FakeRepository(),
        audio,
        'circle-1',
        'visit-1',
      );
      final List<VisitState> emitted = <VisitState>[];
      final StreamSubscription<VisitState> subscription = cubit.stream.listen(
        emitted.add,
      );

      final Future<void> starting = cubit.startRecording();
      await cubit.close();
      audio.permission.complete(false);
      await starting;
      await subscription.cancel();

      expect(emitted, isEmpty);
    });

    test('a denied permission shows the microphone message', () async {
      final _FakeAudio audio = _FakeAudio();
      final VisitCubit cubit = VisitCubit(
        _FakeRepository(),
        audio,
        'circle-1',
        'visit-1',
      );
      addTearDown(cubit.close);

      final Future<void> starting = cubit.startRecording();
      audio.permission.complete(false);
      await starting;

      expect(cubit.state.errorKey, 'appointments.microphone_denied');
      expect(cubit.state.recording, isFalse);
    });

    test('a second tap during the permission prompt starts nothing', () async {
      final _FakeAudio audio = _FakeAudio();
      final VisitCubit cubit = VisitCubit(
        _FakeRepository(),
        audio,
        'circle-1',
        'visit-1',
      );
      addTearDown(cubit.close);

      final Future<void> first = cubit.startRecording();
      await cubit.startRecording();
      audio.permission.complete(false);
      await first;

      expect(audio.starts, 1);
    });
  });
}
