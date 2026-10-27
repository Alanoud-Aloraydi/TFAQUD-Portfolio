import 'dart:async';
import 'dart:io';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int status, [Object? body]) {
  final RequestOptions options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

Map<String, Object> _body(String code) => <String, Object>{
  'error': <String, Object>{'code': code, 'message': 'test'},
};

DioException _of(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

void main() {
  group('FailureExceptions API codes', () {
    final List<(String, int, Failure)> cases = <(String, int, Failure)>[
      ('access_token_expired', 401, const SessionExpiredFailure()),
      ('session_revoked', 401, const SessionExpiredFailure()),
      ('invalid_refresh_token', 401, const SessionExpiredFailure()),
      ('missing_token', 401, const UnauthorizedFailure()),
      ('invalid_token', 401, const UnauthorizedFailure()),
      ('forbidden', 403, const ForbiddenFailure()),
      ('not_found', 404, const NotFoundFailure()),
      ('validation_error', 422, const ValidationFailure()),
      ('bad_request', 400, const ValidationFailure()),
      ('invalid_json', 400, const ValidationFailure()),
      (
        'medication_period_conflict',
        409,
        const ConflictFailure('medications.period_conflict'),
      ),
      (
        'medication_version_conflict',
        409,
        const ConflictFailure('medications.version_conflict'),
      ),
      (
        'dose_record_conflict',
        409,
        const ConflictFailure('medications.dose_record_conflict'),
      ),
      ('data_conflict', 409, const ConflictFailure()),
      ('internal_error', 500, const ServerFailure()),
    ];

    for (final (String code, int status, Failure failure) in cases) {
      test('$code maps to ${failure.runtimeType}', () {
        expect(
          FailureExceptions.getException(_badResponse(status, _body(code))),
          failure,
        );
      });
    }
  });

  group('FailureExceptions status fallback', () {
    final Map<int, Failure> cases = <int, Failure>{
      400: const ValidationFailure(),
      422: const ValidationFailure(),
      401: const UnauthorizedFailure(),
      403: const ForbiddenFailure(),
      404: const NotFoundFailure(),
      409: const ConflictFailure(),
      500: const ServerFailure(),
      502: const ServerFailure(),
      418: const UnknownFailure(),
    };

    cases.forEach((int status, Failure failure) {
      test('$status without an API body maps to ${failure.runtimeType}', () {
        expect(FailureExceptions.getException(_badResponse(status)), failure);
      });
    });
  });

  group('FailureExceptions transport errors', () {
    test('timeouts', () {
      for (final DioExceptionType type in <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          FailureExceptions.getException(_of(type)),
          const TimeoutFailure(),
        );
      }
      expect(
        FailureExceptions.getException(TimeoutException('t')),
        const TimeoutFailure(),
      );
    });

    test('connection error and cancellation', () {
      expect(
        FailureExceptions.getException(_of(DioExceptionType.connectionError)),
        const NetworkFailure(),
      );
      expect(
        FailureExceptions.getException(_of(DioExceptionType.cancel)),
        const CancelledFailure(),
      );
    });

    test('socket errors', () {
      expect(
        FailureExceptions.getException(
          const SocketException('Failed host lookup'),
        ),
        const NetworkFailure(),
      );
      expect(
        FailureExceptions.getException(
          const SocketException('Connection refused'),
        ),
        const ServerFailure(),
      );
    });

    test('format and unknown errors', () {
      expect(
        FailureExceptions.getException(const FormatException('bad')),
        const FormatFailure(),
      );
      expect(FailureExceptions.getException(Object()), const UnknownFailure());
      expect(
        FailureExceptions.getException(_of(DioExceptionType.unknown)),
        const UnknownFailure(),
      );
    });
  });
}
