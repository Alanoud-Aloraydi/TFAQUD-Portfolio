import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'api_options.dart';
import 'auth_interceptor.dart';

@lazySingleton
class DioClient {
  late final Dio _dio;

  DioClient(AuthInterceptor authInterceptor) {
    _dio = Dio(buildApiOptions());
    _dio.interceptors.add(authInterceptor);
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
