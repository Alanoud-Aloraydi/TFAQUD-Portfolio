import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/api_date.dart';
import 'package:injectable/injectable.dart';

/// Data layer contract for the signed-in person's profile on the server.
///
/// Flow: `ProfileRepositoryData` → this data source → PUT
/// /api/v1/accounts/me/profile → the `account` table.
abstract class BaseProfileRemoteDataSource {
  /// Sends the three names, and the birth date and city when given.
  ///
  /// Onboarding sends all five; the account page sends only the names, and
  /// the server then keeps the saved birth date and city. Throws the
  /// [DioClient] error on failure.
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
  });
}

/// HTTP implementation of [BaseProfileRemoteDataSource] over [DioClient].
@LazySingleton(as: BaseProfileRemoteDataSource)
class ProfileRemoteDataSource implements BaseProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

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
        if (birthDate != null) 'birth_date': apiDate(birthDate),
        'city': ?city,
      },
    );
  }
}
