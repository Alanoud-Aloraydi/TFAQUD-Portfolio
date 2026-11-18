import 'dart:async';

import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';

/// Fires once at the patient's next midnight, and again only if scheduled
/// again; it stays silent after [dispose].
class MidnightTimer {
  Timer? _timer;
  bool _disposed = false;

  /// Replaces any earlier wait with one until the patient's next midnight.
  void schedule(
    CareCircleSummary circle,
    DateTime Function() clock,
    void Function() fire,
  ) {
    final DateTime today = circle.clock.today();
    _timer?.cancel();
    final DateTime midnight = circle.clock.momentOf(addDays(today, 1), '00:00');
    _timer = Timer(midnight.difference(clock()), () {
      if (!_disposed) fire();
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
