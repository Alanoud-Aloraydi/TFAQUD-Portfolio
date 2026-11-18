import 'dart:async';

import 'package:app/core/services/push_registration.dart';
import 'package:get_it/get_it.dart';

/// Gives the server this phone's push token once the patient's day is
/// read, as the detailed home does: a missed dose or measurement, and
/// the circle's news, reach the patient in this mode too.
class SimplifiedHomePush {
  /// Whether this phone's push token was asked for in this run.
  bool _started = false;

  /// Asks for the token for [accountId], the first time only.
  void start(String accountId) {
    if (_started) return;
    _started = true;
    unawaited(GetIt.I<PushRegistration>().start(accountId: accountId));
  }
}
