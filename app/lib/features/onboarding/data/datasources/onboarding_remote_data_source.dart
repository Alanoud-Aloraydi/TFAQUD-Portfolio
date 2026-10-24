import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

abstract class BaseOnboardingRemoteDataSource {
  /// Saves account names through PUT /api/v1/accounts/me/profile.
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
