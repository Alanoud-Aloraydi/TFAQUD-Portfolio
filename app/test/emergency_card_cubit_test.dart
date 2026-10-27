import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';

void main() {
  late CirclesFakeRepository circles;
  late EmergencyCardCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    cubit = EmergencyCardCubit(CirclesUseCase(circles), 'circle-1');
  });

  tearDown(() => cubit.close());

  test('starts in the loading state', () {
    expect(cubit.state.status, EmergencyCardStatus.loading);
    expect(cubit.state.card, isNull);
  });

  test('shows the card once it is read', () async {
    await cubit.load();

    expect(cubit.state.status, EmergencyCardStatus.ready);
    expect(cubit.state.card, CirclesFakeRepository.nouraCard);
    expect(cubit.state.card!.fullName, 'نورة العتيبي');
    expect(circles.emergencyCardReads, 1);
  });

  test('every visit reads the card again', () async {
    await cubit.load();
    await cubit.load();

    expect(circles.emergencyCardReads, 2);
  });

  test('a failed read shows the reason and can be tried again', () async {
    circles.emergencyCard = const Error(NetworkFailure());
    await cubit.load();

    expect(cubit.state.status, EmergencyCardStatus.failure);
    expect(cubit.state.messageKey, 'error.network');
    expect(cubit.state.card, isNull);
    expect(cubit.state.sessionEnded, isFalse);

    circles.emergencyCard = Success(CirclesFakeRepository.nouraCard);
    await cubit.load();

    expect(cubit.state.status, EmergencyCardStatus.ready);
    expect(cubit.state.messageKey, isNull);
  });

  test('a person who left the circle is refused', () async {
    circles.emergencyCard = const Error(ForbiddenFailure());

    await cubit.load();

    expect(cubit.state.status, EmergencyCardStatus.failure);
    expect(cubit.state.messageKey, 'error.forbidden');
    expect(cubit.state.sessionEnded, isFalse);
  });

  test('an ended sign-in is told to the page', () async {
    circles.emergencyCard = const Error(SessionExpiredFailure());

    await cubit.load();

    expect(cubit.state.sessionEnded, isTrue);
  });
}
