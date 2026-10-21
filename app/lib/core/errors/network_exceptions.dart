import 'dart:async';
import 'dart:io';

import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';

import 'failure.dart';

class FailureExceptions {
  static Failure getException(Object error) {
    return switch (error) {
      DioException e => _handleDio(e),
      TokenStorageException _ => const StorageFailure('auth.storage_failed'),
      SocketException e => _handleSocket(e),
      FormatException _ => const FormatFailure(),
      TimeoutException _ => const TimeoutFailure(),
      _ => const UnknownFailure(),
    };
  }

  static Failure _handleDio(DioException error) {
    if (error.error is TokenStorageException) {
      return const StorageFailure('auth.storage_failed');
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const TimeoutFailure(),
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.cancel => const CancelledFailure(),
      DioExceptionType.badResponse => _handleResponse(error.response),
      _ => const UnknownFailure(),
    };
  }

  /// The API code takes precedence; the status code is the fallback for
  /// responses that do not have the API error body (for example from a proxy).
  static Failure _handleResponse(Response<dynamic>? response) {
    return switch (apiErrorCode(response?.data)) {
      ApiErrorCodes.accessTokenExpired ||
      ApiErrorCodes.sessionRevoked ||
      ApiErrorCodes.invalidRefreshToken => const SessionExpiredFailure(),
      ApiErrorCodes.missingToken ||
      ApiErrorCodes.invalidToken => const UnauthorizedFailure(),
      ApiErrorCodes.forbidden => const ForbiddenFailure(),
      ApiErrorCodes.notFound => const NotFoundFailure(),
      ApiErrorCodes.validationError ||
      ApiErrorCodes.badRequest ||
      ApiErrorCodes.invalidJson => const ValidationFailure(),
      ApiErrorCodes.internalError => const ServerFailure(),
      _ => _handleStatusCode(response?.statusCode),
    };
  }

  static Failure _handleStatusCode(int? code) {
    return switch (code) {
      400 || 422 => const ValidationFailure(),
      401 => const UnauthorizedFailure(),
      403 => const ForbiddenFailure(),
      404 => const NotFoundFailure(),
      _ when code != null && code >= 500 => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }

  static Failure _handleSocket(SocketException error) {
    final message = error.message.toLowerCase();

    if (message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('no address associated')) {
      return const NetworkFailure();
    }
    if (message.contains('connection refused')) {
      return const ServerFailure();
    }
    if (message.contains('timed out')) {
      return const TimeoutFailure();
    }

    return const NetworkFailure();
  }
}
