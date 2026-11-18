import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:dio/dio.dart' show Response;
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';

/// Calls GET /health and returns the address used and the result.
Future<String> checkGalleryApi() async {
  try {
    final Response<dynamic> response = await GetIt.I<DioClient>().get(
      ApiEndpoints.health,
    );
    return 'GET ${ApiEndpoints.baseUrl}${ApiEndpoints.health}\n'
        'HTTP ${response.statusCode}';
  } catch (error) {
    final Failure failure = FailureExceptions.getException(error);
    return '${failure.messageKey.tr()} (${error.runtimeType})';
  }
}
