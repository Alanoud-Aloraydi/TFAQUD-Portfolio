import 'dart:io';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_failures.dart';

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
