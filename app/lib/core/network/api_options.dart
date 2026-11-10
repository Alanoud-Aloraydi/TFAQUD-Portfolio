import 'package:dio/dio.dart';

import 'api_endpoints.dart';

/// Options shared by the main client and the interceptor's own client.
BaseOptions buildApiOptions() {
  return BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: const <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
}
