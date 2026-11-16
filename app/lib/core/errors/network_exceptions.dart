import 'dart:async';
import 'dart:io';

import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/dio_failure.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/generic_failures.dart';
import 'package:app/core/errors/network_failures.dart';
import 'package:app/core/errors/socket_failure.dart';
import 'package:app/core/errors/storage_failures.dart';
import 'package:app/core/services/token_storage.dart';
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
