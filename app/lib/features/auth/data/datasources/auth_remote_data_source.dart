import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

abstract class BaseAuthRemoteDataSource {
  /// POST /api/v1/auth/sign-out. The API answers 204 with an empty body.
  Future<void> signOut();
}

@LazySingleton(as: BaseAuthRemoteDataSource)
class AuthRemoteDataSource implements BaseAuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<void> signOut() async {
    // No try/catch here: the repository turns any error into a Failure, once.
    // The interceptor adds the access token to this request.
    await _client.post(ApiEndpoints.signOut);
  }
}
