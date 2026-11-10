import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/home/data/models/home_model.dart';
import 'package:injectable/injectable.dart';

/// Sends base home requests to the API.
abstract class BaseHomeRemoteDataSource {
  Future<HomeModel> getHome();
}

@LazySingleton(as: BaseHomeRemoteDataSource)
/// Sends home requests to the API.
class HomeRemoteDataSource implements BaseHomeRemoteDataSource {
  HomeRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<HomeModel> getHome() async {
    final response = await _client.get(ApiEndpoints.home);
    return HomeModel.fromJson(response.data as Map<String, dynamic>);
  }
}
