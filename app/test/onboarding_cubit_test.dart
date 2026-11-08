import 'package:app/core/errors/failure.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

class _Onboarding implements OnboardingRepositoryDomain {
  final List<Map<String, Object?>> saved = <Map<String, Object?>>[];

  @override
  Future<Result<bool, Failure>> saveProfile({
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
    return const Success(true);
  }
}

void main() {
  late _Onboarding repository;
  late OnboardingCubit cubit;

  setUp(() {
    repository = _Onboarding();
    cubit = OnboardingCubit(OnboardingUseCase(repository));
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
    expect(cubit.state.status, OnboardingStatus.saved);
    expect(repository.saved.single, <String, Object?>{
      'first': 'Reem',
      'last': 'Alahmadi',
      'display': 'Reem',
      'birthDate': DateTime(1990, 3, 4),
      'city': 'الرياض',
    });
  });
}
