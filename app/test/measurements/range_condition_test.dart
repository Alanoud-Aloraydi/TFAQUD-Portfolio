import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';
import '../support/normal_ranges.dart';

class _Measurements extends Fake implements MeasurementRepository {
  int reads = 0;

  @override
  Future<NormalRanges> ranges(String circleId) async {
    reads++;
    return generalRanges();
  }
}

/// «الحالة» under a reading's «المعدل الطبيعي»: changing it there saves the
/// medical file's conditions and nothing else, then reads the ranges again.
void main() {
  group('ConditionsDraft.withCode', () {
    test('adds a condition to the ones already listed', () {
      expect(
        ConditionsDraft.withCode(
          const ConditionsDraft.listed(codes: <String>['asthma']),
          'diabetes',
          has: true,
        ),
        const ConditionsDraft.listed(codes: <String>['asthma', 'diabetes']),
      );
    });

    test('an unanswered or "none" list becomes that one condition', () {
      const ConditionsDraft diabetes = ConditionsDraft.listed(
        codes: <String>['diabetes'],
      );
      expect(ConditionsDraft.withCode(null, 'diabetes', has: true), diabetes);
      expect(
        ConditionsDraft.withCode(
          const ConditionsDraft.none(),
          'diabetes',
          has: true,
        ),
        diabetes,
      );
    });

    test('taking one out keeps the rest and the typed "other"', () {
      expect(
        ConditionsDraft.withCode(
          const ConditionsDraft.listed(
            codes: <String>['hypertension', 'other'],
            other: 'نقرس',
          ),
          'hypertension',
          has: false,
        ),
        const ConditionsDraft.listed(codes: <String>['other'], other: 'نقرس'),
      );
    });

    test('taking out the last one answers "none"; unknown stays unknown', () {
      expect(
        ConditionsDraft.withCode(
          const ConditionsDraft.listed(codes: <String>['diabetes']),
          'diabetes',
          has: false,
        ),
        const ConditionsDraft.none(),
      );
      expect(ConditionsDraft.withCode(null, 'diabetes', has: false), isNull);
    });
  });

  group('MeasurementRangesCubit.setCondition', () {
    late CirclesFakeRepository circles;
    late _Measurements measurements;
    late MeasurementRangesCubit cubit;

    setUp(() async {
      circles = CirclesFakeRepository();
      measurements = _Measurements();
      cubit = MeasurementRangesCubit(measurements, CirclesUseCase(circles));
      await cubit.load('circle-1');
    });

    tearDown(() => cubit.close());

    test('saves the condition with the rest of the file as it was', () async {
      expect(
        await cubit.setCondition('circle-1', 'hypertension', has: true),
        isNull,
      );

      final MedicalProfileDraft saved = circles.profileUpdates.single;
      expect(saved.bloodType, 'O+');
      expect(saved.allergies, const AllergiesDraft.none());
      expect(
        saved.conditions,
        const ConditionsDraft.listed(
          codes: <String>['diabetes', 'hypertension'],
        ),
      );
    });

    test('reads the ranges again, keeping the old ones on screen', () async {
      final List<MeasurementRangesState> seen = <MeasurementRangesState>[];
      final sub = cubit.stream.listen(seen.add);
      addTearDown(sub.cancel);

      await cubit.setCondition('circle-1', 'diabetes', has: false);
      await Future<void>.delayed(Duration.zero);

      expect(measurements.reads, 2);
      expect(seen.every((s) => s.ranges != null), isTrue);
      expect(cubit.state.ranges?.of(MeasurementKind.bp), isNotNull);
    });

    test('a failed save says why and saves nothing else', () async {
      circles.profileSaved = const Error<MedicalProfileDraft, Failure>(
        NetworkFailure(),
      );

      expect(
        await cubit.setCondition('circle-1', 'diabetes', has: false),
        const NetworkFailure().messageKey,
      );
      expect(measurements.reads, 1);
    });

    test('without the medical file it cannot save', () async {
      final MeasurementRangesCubit readOnly = MeasurementRangesCubit(
        measurements,
      );
      addTearDown(readOnly.close);

      expect(
        await readOnly.setCondition('circle-1', 'diabetes', has: true),
        'error.unknown',
      );
    });
  });
}
