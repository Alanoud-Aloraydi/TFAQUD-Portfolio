import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/circles/data/models/account_model.dart';
import 'package:app/features/circles/data/models/circle_model.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:injectable/injectable.dart';

abstract class BaseCirclesRemoteDataSource {
  /// GET /api/v1/accounts/me.
  Future<AccountModel> getAccount();

  /// POST /api/v1/circles/self.
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body);
}

@LazySingleton(as: BaseCirclesRemoteDataSource)
class CirclesRemoteDataSource implements BaseCirclesRemoteDataSource {
  CirclesRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<AccountModel> getAccount() async {
    final response = await _client.get(ApiEndpoints.account);
    return AccountModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body) async {
    final response = await _client.post(
      ApiEndpoints.selfCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }
}
