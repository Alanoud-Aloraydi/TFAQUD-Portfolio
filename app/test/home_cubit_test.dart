import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/home_fakes.dart';

void main() {
  late HomeFakeRepository repository;
  late HomeCubit cubit;

  setUp(() {
    repository = HomeFakeRepository();
    cubit = HomeCubit(HomeUseCase(repository));
  });

  tearDown(() => cubit.close());

  test('restores a selection authorized by the current response', () async {
    repository.selections['account-a'] = 'two';
    await cubit.load();
    expect(cubit.state.selectedCircleId, 'two');
    expect(cubit.state.status, HomeStatus.ready);
  });

  test('falls back when the saved circle is no longer accessible', () async {
    repository.selections['account-a'] = 'removed';
    await cubit.load();
    expect(cubit.state.selectedCircleId, 'one');
    expect(repository.selections['account-a'], 'one');
  });

  test(
    'persists the default before another circle changes list order',
    () async {
      await cubit.load();
      repository.response = Success(
        homeData(
          circles: [
            const CareCircleSummary(id: 'new', name: 'A new circle'),
            ...homeData().circles,
          ],
        ),
      );
      await cubit.load();
      expect(cubit.state.selectedCircleId, 'one');
    },
  );

  test('failure to save a default does not hide authorized circles', () async {
    repository.saveFails = true;
    await cubit.load();
    expect(cubit.state.status, HomeStatus.ready);
    expect(cubit.state.selectedCircleId, 'one');
  });

  test('empty circles are successful with no selection', () async {
    repository.response = Success(homeData(circles: []));
    await cubit.load();
    expect(cubit.state.status, HomeStatus.ready);
    expect(cubit.state.selectedCircleId, isNull);
  });

  test('selection survives a new home instance for the same account', () async {
    await cubit.load();
    await cubit.selectCircle('two');
    await cubit.close();
    cubit = HomeCubit(HomeUseCase(repository));
    await cubit.load();
    expect(cubit.state.selectedCircleId, 'two');
  });

  test('another account does not inherit the previous selection', () async {
    await cubit.load();
    await cubit.selectCircle('two');
    repository.response = Success(homeData(accountId: 'account-b'));
    await cubit.load();
    expect(cubit.state.selectedCircleId, 'one');
    expect(repository.selections['account-b'], 'one');
  });

  test('ignores an identifier outside the authorized circle list', () async {
    await cubit.load();
    await cubit.selectCircle('unknown');
    expect(cubit.state.selectedCircleId, 'one');
    expect(repository.selections, {'account-a': 'one'});
  });

  test(
    'storage failure keeps the previous selection and reports failure',
    () async {
      await cubit.load();
      repository.saveFails = true;
      await cubit.selectCircle('two');
      expect(cubit.state.selectedCircleId, 'one');
      expect(cubit.state.messageKey, 'home.selection_failed');
    },
  );

  test('failed refresh hides previous data and can be retried', () async {
    await cubit.load();
    repository.response = const Error(NetworkFailure());
    await cubit.load();
    expect(cubit.state.status, HomeStatus.failure);
    expect(cubit.state.data, isNull);
    repository.response = Success(homeData());
    await cubit.load();
    expect(cubit.state.status, HomeStatus.ready);
  });

  test('expired session returns to sign-in with no retained data', () async {
    await cubit.load();
    repository.response = const Error(SessionExpiredFailure());
    await cubit.load();
    expect(cubit.state.status, HomeStatus.signIn);
    expect(cubit.state.data, isNull);
  });

  test('incomplete account goes to the existing onboarding flow', () async {
    repository.response = Success(homeData(profileComplete: false));
    await cubit.load();
    expect(cubit.state.status, HomeStatus.onboarding);
    expect(cubit.state.data, isNull);
  });

  test('an older response cannot replace a newer account load', () async {
    final old = Completer<Result<HomeEntity, Failure>>();
    repository.pending = old.future;
    final earlier = cubit.load();
    repository.pending = null;
    repository.response = Success(homeData(accountId: 'account-b'));
    await cubit.load();
    old.complete(Success(homeData()));
    await earlier;
    expect(cubit.state.data!.accountId, 'account-b');
  });

  test('completion after disposal does not emit or throw', () async {
    final pending = Completer<Result<HomeEntity, Failure>>();
    repository.pending = pending.future;
    final load = cubit.load();
    await cubit.close();
    pending.complete(Success(homeData()));
    await load;
  });
}
