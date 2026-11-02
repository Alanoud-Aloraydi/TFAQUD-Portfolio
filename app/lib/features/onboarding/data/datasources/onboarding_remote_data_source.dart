import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:injectable/injectable.dart';

abstract class BaseOnboardingRemoteDataSource {
  /// Saves the account names through PUT /api/v1/accounts/me/profile, with
  /// the birth date and city when onboarding sends them.
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
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
    DateTime? birthDate,
    String? city,
  }) async {
    await _client.put(
      ApiEndpoints.profile,
      data: <String, String>{
        'first_name': firstName,
        'last_name': lastName,
        'display_name': displayName,
        // Onboarding sends both; the account page sends only the names, and
        // the server keeps the saved ones.
        if (birthDate != null)
          'birth_date': NewSelfCircleModel.isoDate(birthDate),
        'city': ?city,
      },
    );
  }
}
