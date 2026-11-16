import 'package:app/core/errors/appointment_api_failures.dart';
import 'package:app/core/errors/auth_api_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/measurement_api_failures.dart';
import 'package:app/core/errors/medication_api_failures.dart';
import 'package:app/core/errors/status_code_failure.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:dio/dio.dart';

/// The API code takes precedence; the status code is the fallback for
/// responses that do not have the API error body (for example from a proxy).
Failure responseFailure(Response<dynamic>? response) {
  final String? code = apiErrorCode(response?.data);
  return authApiFailure(code) ??
      medicationApiFailure(code) ??
      measurementApiFailure(code) ??
      appointmentApiFailure(code) ??
      statusCodeFailure(response?.statusCode);
}
