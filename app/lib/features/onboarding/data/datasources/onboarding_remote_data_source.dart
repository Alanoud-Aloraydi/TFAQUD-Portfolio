import 'package:injectable/injectable.dart';

abstract class BaseOnboardingRemoteDataSource {
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  });
}

/// The profile endpoint is not built in the API yet, so [saveProfile] answers
/// on the phone. Replace its body with a `DioClient` call when the endpoint
/// exists; no other file changes.
@LazySingleton(as: BaseOnboardingRemoteDataSource)
class OnboardingRemoteDataSource implements BaseOnboardingRemoteDataSource {
  @override
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
