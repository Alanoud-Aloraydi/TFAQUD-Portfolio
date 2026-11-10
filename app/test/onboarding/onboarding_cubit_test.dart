import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/repositories/profile_repository_domain.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

class _Profile implements ProfileRepositoryDomain {
  Result<void, Failure> result = const Success(null);
  final List<Map<String, Object?>> saved = <Map<String, Object?>>[];

  @override
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) async {
    saved.add(<String, Object?>{
      'first': firstName,
      'last': lastName,
      'display': displayName,
      'birthDate': birthDate,
      'city': city,
    });
    return result;
  }
}

void main() {
  group('OnboardingCubit', () {
    late _Profile repository;
    late OnboardingCubit cubit;

    setUp(() {
      repository = _Profile();
      cubit = OnboardingCubit(ProfileUseCase(repository));
    });

    tearDown(() => cubit.close());

    void typeNames() {
      cubit
        ..firstNameChanged(' Reem ')
        ..lastNameChanged('Alahmadi')
        ..displayNameChanged('Reem');
    }

    test(
      'the names alone are not enough: the birth date and city are asked',
      () async {
        typeNames();

        final bool saved = await cubit.saveProfile();

        expect(saved, isFalse);
        expect(cubit.state.showErrors, isTrue);
        expect(repository.saved, isEmpty);
      },
    );

    test('saves the names with the birth date and city', () async {
      typeNames();
      cubit
        ..birthDateChanged(DateTime(1990, 3, 4))
        ..cityChanged('الرياض');

      final bool saved = await cubit.saveProfile();

      expect(saved, isTrue);
      expect(cubit.state.status, OnboardingStatus.idle);
      expect(repository.saved.single, <String, Object?>{
        'first': 'Reem',
        'last': 'Alahmadi',
        'display': 'Reem',
        'birthDate': DateTime(1990, 3, 4),
        'city': 'الرياض',
      });
    });

    void fillEverything() {
      typeNames();
      cubit
        ..birthDateChanged(DateTime(1990, 3, 4))
        ..cityChanged('الرياض');
    }

    test('an ended sign-in sets sessionEnded and shows no error', () async {
      repository.result = const Error(SessionExpiredFailure());
      fillEverything();

      final bool saved = await cubit.saveProfile();

      expect(saved, isFalse);
      expect(cubit.state.sessionEnded, isTrue);
      expect(cubit.state.errorKey, isNull);
    });

    test('any other failure keeps the answers and shows its message', () async {
      repository.result = const Error(InvalidBirthDateFailure());
      fillEverything();

      await cubit.saveProfile();

      expect(cubit.state.sessionEnded, isFalse);
      expect(cubit.state.errorKey, 'common.invalid_birth_date');
      expect(cubit.state.firstName, ' Reem ');
      expect(cubit.state.status, OnboardingStatus.idle);
    });
  });
}
