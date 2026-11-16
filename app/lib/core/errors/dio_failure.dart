import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/generic_failures.dart';
import 'package:app/core/errors/network_failures.dart';
import 'package:app/core/errors/response_failure.dart';
import 'package:app/core/errors/storage_failures.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';

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
