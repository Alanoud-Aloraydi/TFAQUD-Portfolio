import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import 'support/circles_fakes.dart';

void main() {
  late CirclesFakeRepository circles;
  late RequestReplyCubit cubit;

  setUp(() {
    circles = CirclesFakeRepository();
    cubit = RequestReplyCubit(
      CirclesUseCase(circles),
      CirclesFakeRepository.askedOfNoura,
    );
  });

  tearDown(() => cubit.close());

  test('agreeing sends the answer for this request and moves on', () async {
    await cubit.accept();
    expect(
      circles.requestAnswers.single,
      ('request-in-1', true),
    );
    expect(cubit.state.outcome, ReplyOutcome.accepted);
    expect(cubit.state.sending, isFalse);
    expect(cubit.state.errorKey, isNull);
  });

  test('declining sends "no" and goes back', () async {
    circles.replied = const Success(CircleRequestStatus.declined);
    await cubit.decline();
    expect(
      circles.requestAnswers.single,
      ('request-in-1', false),
    );
    expect(cubit.state.outcome, ReplyOutcome.declined);
  });

  test('a request that is gone shows its text and stays on the page',
      () async {
    circles.replied = const Error(RequestUnavailableFailure());
    await cubit.accept();
    expect(cubit.state.outcome, ReplyOutcome.none);
    expect(cubit.state.errorKey, 'circles.request_unavailable');
    expect(cubit.state.sending, isFalse);
  });

  test('a mode that does not fit shows its own text', () async {
    circles.replied = const Error(ReplyModeConflictFailure());
    await cubit.accept();
    expect(cubit.state.errorKey, 'circles.reply_mode_conflict');
  });

  test('a second try clears the old message', () async {
    circles.replied = const Error(NetworkFailure());
    await cubit.accept();
    expect(cubit.state.errorKey, 'error.network');
    circles.replied = const Success(CircleRequestStatus.accepted);
    await cubit.accept();
    expect(cubit.state.errorKey, isNull);
    expect(cubit.state.outcome, ReplyOutcome.accepted);
  });

  test('an ended sign-in is reported', () async {
    circles.replied = const Error(UnauthorizedFailure());
    await cubit.decline();
    expect(cubit.state.sessionEnded, isTrue);
  });
}
