import 'package:app/core/errors/failure.dart';
import 'package:multiple_result/multiple_result.dart';

/// Domain contract for saving the signed-in person's profile.
///
/// Flow: `ProfileUseCase` → this contract → `ProfileRepositoryData` (data
/// layer). The domain layer depends on this interface, never on the HTTP
/// code behind it.
abstract class ProfileRepositoryDomain {
  /// Saves the full name, the display name other circle members see, and
  /// the birth date and city when given (onboarding gives them, so a circle
  /// for the person's own care needs only its name). A null birth date or
  /// city keeps the saved one.
  Future<Result<void, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  });
}
