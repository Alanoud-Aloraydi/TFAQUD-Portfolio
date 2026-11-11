import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';

void main() {
  group('CircleOverviewCubit member access', () {
    late CirclesFakeRepository circles;
    late CircleOverviewCubit cubit;

    setUp(() async {
      circles = CirclesFakeRepository();
      cubit = CircleOverviewCubit(CirclesUseCase(circles), 'circle-1');
      await cubit.load();
    });

    tearDown(() => cubit.close());

    test('pausing a member sends the choice and reads the circle', () async {
      final int reads = circles.circleOverviewReads;

      expect(await cubit.setMemberEditAccess('a-2', canEdit: false), isNull);

      expect(circles.memberCalls.single, 'access:a-2:false');
      expect(circles.circleOverviewReads, reads + 1);
      expect(cubit.state.acting, isFalse);
    });

    test('removing a member sends the call and reads the circle', () async {
      final int reads = circles.circleOverviewReads;

      expect(await cubit.removeMember('a-2'), isNull);

      expect(circles.memberCalls.single, 'remove:a-2');
      expect(circles.circleOverviewReads, reads + 1);
    });

    test('a refused change shows its text and keeps the tab', () async {
      circles.invitationChanged = const Error(ValidationFailure());
      final int reads = circles.circleOverviewReads;

      expect(
        await cubit.setMemberEditAccess('a-2', canEdit: true),
        'error.invalid_data',
      );

      expect(circles.circleOverviewReads, reads);
    });

    test('a member who is gone already reads the circle again', () async {
      circles.invitationChanged = const Error(NotFoundFailure());
      final int reads = circles.circleOverviewReads;

      expect(await cubit.removeMember('a-2'), 'error.resource_not_found');

      expect(circles.circleOverviewReads, reads + 1);
    });

    test('a lost access reads the circle again', () async {
      circles.invitationChanged = const Error(ForbiddenFailure());
      final int reads = circles.circleOverviewReads;

      await cubit.setMemberEditAccess('a-2', canEdit: false);

      expect(circles.circleOverviewReads, reads + 1);
    });

    test('a closed cubit does not emit after the answer', () async {
      circles.invitationChanged = const Success(null);
      final Future<String?> pending = cubit.removeMember('a-2');
      await cubit.close();

      expect(await pending, isNull);
    });
  });
}
