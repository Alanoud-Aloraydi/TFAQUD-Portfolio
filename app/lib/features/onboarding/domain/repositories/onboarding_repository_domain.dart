import 'package:app/core/errors/failure.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class OnboardingRepositoryDomain {
  /// Saves the name of the new user: full name parts and the display name that
  /// other members of a circle see.
  Future<Result<bool, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  });
}
