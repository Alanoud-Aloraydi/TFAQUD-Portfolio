import 'dart:ui' show Size;

import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/repositories/profile_repository.dart';
import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_name_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

import '../support/circles_fakes.dart';
import '../support/home_fakes.dart';
import '../support/widget_harness.dart';

/// Keeps the names it is asked to save.
class _Profile extends Fake implements ProfileRepository {
  final List<List<String>> saved = <List<String>>[];

  @override
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) async {
    saved.add(<String>[firstName, lastName, displayName]);
    return const Success(null);
  }
}

/// Never asked: the page signs no one out.
class _Auth extends Fake implements AuthRepository {}

void main() {
  group('«الاسم» of the simplified «حسابي»', () {
    setUpAll(initTestLocalization);

    late _Profile profile;
    late AccountCubit cubit;

    setUp(() {
      profile = _Profile();
      cubit = AccountCubit(
        CirclesUseCase(CirclesFakeRepository()),
        ProfileUseCase(profile),
        AuthUseCase(_Auth()),
        HomeUseCase(HomeFakeRepository()),
      );
    });
    tearDown(() => cubit.close());

    /// The page over an account already read, on a screen tall enough
    /// for the three names and the note under them.
    Future<void> open(WidgetTester tester) async {
      await cubit.load();
      await pumpArabic(
        tester,
        home: BlocProvider<AccountCubit>.value(
          value: cubit,
          child: const SimplifiedNameScreen(),
        ),
      );
      tester.view.physicalSize = const Size(400, 2400);
      await tester.pump();
    }

    testWidgets('opens with the three names of the account', (tester) async {
      await open(tester);

      expect(find.byType(TextField), findsNWidgets(3));
      // «Reem» is both the first name and the display name.
      expect(find.text('Reem'), findsNWidgets(2));
      expect(find.text('Alahmadi'), findsOneWidget);
    });

    testWidgets('a name left empty says «هذا الحقل مطلوب» and saves '
        'nothing', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField).at(2), '');
      await tester.tap(find.text('account.save'.tr()));
      await tester.pump();

      expect(find.text('common.field_required'.tr()), findsOneWidget);
      expect(profile.saved, isEmpty);
    });
  });
}
