import 'dart:async';

import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends Fake implements MeasurementRepository {
  final requests = <String, Completer<List<MeasurementReading>>>{};

  @override
  Future<List<MeasurementReading>> readings(
    String circleId,
    DateTime from,
    DateTime to,
  ) {
    final request = Completer<List<MeasurementReading>>();
    requests[circleId] = request;
    return request.future;
  }
}

void main() {
  test('switching circles clears the previous patient readings', () async {
    final repository = _Repository();
    final cubit = MeasurementReadingsCubit(repository);
    final day = DateTime(2026, 11, 3);
    final first = cubit.load('patient-a', day, day);
    repository.requests['patient-a']!.complete([
      MeasurementReading(
        id: 'reading-a',
        kind: MeasurementKind.glucose,
        outcome: 'read',
        recordedAt: day,
        measuredAt: day,
        valueOne: 120,
      ),
    ]);
    await first;
    expect(cubit.state.readings, hasLength(1));

    final second = cubit.load('patient-b', day, day);
    expect(cubit.state.status, MeasurementLoadStatus.loading);
    expect(cubit.state.readings, isEmpty);
    repository.requests['patient-b']!.complete([]);
    await second;
    await cubit.close();
  });
}
