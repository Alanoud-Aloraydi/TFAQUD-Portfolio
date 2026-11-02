import 'package:app/core/errors/failure.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class OnboardingRepositoryDomain {
  /// Saves the new user's full name, the display name that other members of a
  /// circle see, and the birth date and city (so a circle for their own care
  /// needs only its name).
  Future<Result<bool, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  });
}
