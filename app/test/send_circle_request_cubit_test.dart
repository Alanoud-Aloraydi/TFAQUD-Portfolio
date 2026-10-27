import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';

void main() {
  late CirclesFakeRepository circles;
  late SendCircleRequestCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    cubit = SendCircleRequestCubit(CirclesUseCase(circles));
  });

  tearDown(() => cubit.close());

  group('the phone number', () {
    test('is nine digits that start with 5', () {
      for (final String bad in <String>[
        '',
        '5',
        '12345678',
        '412345678',
        '5123456789',
        '50123456a',
        '050123456',
      ]) {
        cubit.phoneChanged(bad);
        expect(cubit.isPhoneValid, isFalse, reason: 'number "$bad"');
      }
      cubit.phoneChanged('501234567');
      expect(cubit.isPhoneValid, isTrue);
    });

    test('a wrong number sends nothing and asks to correct it', () async {
      cubit.phoneChanged('1234');
      expect(await cubit.send(labelName: 'أمي'), isFalse);
      expect(cubit.state.showErrors, isTrue);
      expect(circles.sentRequests, isEmpty);
    });
  });

  group('the label', () {
    test('a label of your own needs its text', () async {
      cubit.phoneChanged('501234567');
      cubit.chooseLabel(CircleLabel.other);
      expect(await cubit.send(labelName: 'اسم آخر'), isFalse);
      cubit.customLabelChanged('   ');
      expect(await cubit.send(labelName: 'اسم آخر'), isFalse);
      expect(circles.sentRequests, isEmpty);
      cubit.customLabelChanged('  عمي ');
      expect(await cubit.send(labelName: 'اسم آخر'), isTrue);
      expect(circles.sentRequests.single.circleLabel, 'عمي');
    });
  });

  group('send', () {
    test('sends the number with +966, the label and the simplified mode', () async {
      cubit.phoneChanged('501234567');
      expect(await cubit.send(labelName: 'أمي'), isTrue);
      expect(
        circles.sentRequests.single,
        const NewCircleRequest(
          patientPhoneNumber: '+966501234567',
          circleLabel: 'أمي',
          proposedAppMode: CircleAppMode.simplified,
        ),
      );
    });

    test('sends the mode that was chosen', () async {
      cubit.phoneChanged('501234567');
      cubit.chooseMode(CircleAppMode.detailed);
      expect(await cubit.send(labelName: 'أمي'), isTrue);
      expect(
        circles.sentRequests.single.proposedAppMode,
        CircleAppMode.detailed,
      );
    });

    test('keeps the request the server saved and moves to "sent"', () async {
      cubit.phoneChanged('501234567');
      expect(await cubit.send(labelName: 'أمي'), isTrue);
      expect(cubit.state.status, SendStatus.sent);
      expect(cubit.state.sent, CirclesFakeRepository.waitingRequest);
    });

    test('a refusal keeps the form and shows its text', () async {
      cubit.phoneChanged('501234567');
      circles.sent = const Error(SelfRequestFailure());
      expect(await cubit.send(labelName: 'أمي'), isFalse);
      expect(cubit.state.status, SendStatus.idle);
      expect(cubit.state.errorKey, 'circles.self_request');
      expect(cubit.state.sent, isNull);
      expect(cubit.state.phone, '501234567');
      expect(cubit.state.sessionEnded, isFalse);
    });

    test('typing again clears the refusal', () async {
      cubit.phoneChanged('501234567');
      circles.sent = const Error(PatientHasCircleFailure());
      await cubit.send(labelName: 'أمي');
      expect(cubit.state.errorKey, 'circles.patient_has_circle');
      cubit.phoneChanged('501234568');
      expect(cubit.state.errorKey, isNull);
    });

    test('an ended session is reported', () async {
      cubit.phoneChanged('501234567');
      circles.sent = const Error(UnauthorizedFailure());
      expect(await cubit.send(labelName: 'أمي'), isFalse);
      expect(cubit.state.sessionEnded, isTrue);
    });

    test('a failure of the network is shown', () async {
      cubit.phoneChanged('501234567');
      circles.sent = const Error(NetworkFailure());
      expect(await cubit.send(labelName: 'أمي'), isFalse);
      expect(cubit.state.errorKey, 'error.network');
    });
  });
}
