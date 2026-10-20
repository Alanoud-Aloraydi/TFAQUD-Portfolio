import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

abstract class BaseOnboardingRemoteDataSource {
  /// PUT /api/v1/users/me/profile. Saves the three names of the signed-in
  /// user and replaces the earlier values. The interceptor adds the access
  /// token that was saved when the code was verified.
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  });
}

@LazySingleton(as: BaseOnboardingRemoteDataSource)
class OnboardingRemoteDataSource implements BaseOnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    // No try/catch: the repository turns any error into a Failure, once.
    await _client.put(
      ApiEndpoints.profile,
      data: <String, String>{
        'first_name': firstName,
        'last_name': lastName,
        'display_name': displayName,
      },
    );
  }
}
