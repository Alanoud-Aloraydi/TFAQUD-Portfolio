import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

void main() {
  test('record filter changes without reloading plans', () {
    final repository = _PlansRepository();
    final cubit = MedicationsCubit(MedicationsUseCase(repository));
    addTearDown(cubit.close);

    expect(cubit.state.recordFilter, MedicationRecordFilter.all);
    cubit.setRecordFilter(MedicationRecordFilter.previous);

    expect(cubit.state.recordFilter, MedicationRecordFilter.previous);
    expect(repository.calls, isEmpty);
  });

  test('an older circle response cannot replace the latest circle', () async {
    final repository = _PlansRepository();
    final cubit = MedicationsCubit(MedicationsUseCase(repository));
    addTearDown(cubit.close);
    final old = Completer<Result<List<MedicationPlan>, Failure>>();
    final latest = Completer<Result<List<MedicationPlan>, Failure>>();
    repository.responses.addAll([old.future, latest.future]);

    final oldLoad = cubit.load('circle-old');
    final latestLoad = cubit.load('circle-latest');
    latest.complete(const Success([]));
    await latestLoad;
    old.complete(const Error(ServerFailure('error.unknown')));
    await oldLoad;

    expect(repository.calls, ['circle-old', 'circle-latest']);
    expect(cubit.state.status, MedicationsStatus.ready);
    expect(cubit.state.messageKey, isNull);
  });
}

class _PlansRepository extends Fake implements MedicationsRepositoryDomain {
  final responses = <Future<Result<List<MedicationPlan>, Failure>>>[];
  final calls = <String>[];

  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(
    String circleId,
  ) {
    calls.add(circleId);
    return responses.removeAt(0);
  }
}
