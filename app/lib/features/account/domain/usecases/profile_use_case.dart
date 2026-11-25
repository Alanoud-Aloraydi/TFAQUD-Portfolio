import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/domain/repositories/profile_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// Use case for saving the signed-in person's profile.
///
/// Flow: `OnboardingCubit` (first set-up) or `AccountCubit` (account page)
/// → this use case → [ProfileRepository]. One entry point, so both
/// pages save the profile the same way.
class ProfileUseCase {
  ProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Saves the names, and the birth date and city when given. See
  /// [ProfileRepository.saveProfile].
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  }) {
    return _repository.saveProfile(
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      birthDate: birthDate,
      city: city,
    );
  }
}
