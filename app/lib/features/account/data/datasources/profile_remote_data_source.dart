import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/api_date.dart';

/// Data layer contract for the signed-in person's profile on the server.
///
/// Flow: `ProfileRepositoryImpl` → this data source → PUT
/// /api/v1/accounts/me/profile → the `account` table.
abstract class BaseProfileRemoteDataSource {
  /// Sends the three names, and the birth date and the city with its
  /// [timeZone] when given.
  ///
  /// Onboarding sends the birth date and city; the account page sends a
  /// city only when it changed. The server keeps what is left out, and
  /// moves the zone of the circle the account is the patient of to
  /// [timeZone]. Throws the [DioClient] error on failure.
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    DateTime? birthDate,
    String? city,
    String? timeZone,
  });
}

/// HTTP implementation of [BaseProfileRemoteDataSource] over [DioClient].
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
    String? timeZone,
  }) async {
    await _client.put(
      AccountEndpoints.profile,
      data: <String, String>{
        'first_name': firstName,
        'last_name': lastName,
        'display_name': displayName,
        if (birthDate != null) 'birth_date': apiDate(birthDate),
        'city': ?city,
        'time_zone': ?timeZone,
      },
    );
  }
}
