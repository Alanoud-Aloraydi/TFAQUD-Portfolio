import 'dart:async';
import 'dart:io';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/generic_failures.dart';
import 'package:app/core/errors/response_failure.dart';
import 'package:app/core/errors/storage_failures.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Maps network failures to app error types.
class FailureExceptions {
  static Failure getException(Object error) {
    return switch (error) {
      DioException e => dioFailure(e),
      TokenStorageException _ => const StorageFailure('auth.storage_failed'),
      SocketException e => socketFailure(e),
      FormatException _ => const FormatFailure(),
      TimeoutException _ => const TimeoutFailure(),
      _ => const UnknownFailure(),
    };
  }
}

/// What a Dio error means to the app, by its kind.
Failure dioFailure(DioException error) {
  if (error.error is TokenStorageException) {
    return const StorageFailure('auth.storage_failed');
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.cancel => const CancelledFailure(),
    DioExceptionType.badResponse => responseFailure(error.response),
    _ => const UnknownFailure(),
  };
}

/// A socket says what went wrong in its message only, so the message is what
/// is read: no address and no route are the phone's own network, a refused
/// connection is the server.
Failure socketFailure(SocketException error) {
  final String message = error.message.toLowerCase();

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

class ServerFailure extends Failure {
  const ServerFailure([super.messageKey = 'error.server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.messageKey = 'error.network']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.messageKey = 'error.timeout']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.messageKey = 'error.resource_not_found']);
}
