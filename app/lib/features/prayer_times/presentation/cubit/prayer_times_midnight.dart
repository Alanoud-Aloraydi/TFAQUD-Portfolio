import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_scope.dart';

/// Reading the times again when the patient's day changes.
mixin PrayerTimesMidnight on PrayerTimesScope {
  Future<void> load(String circleId, String timeZone, {bool refresh = false});

  /// A new day of the patient: reads the times unless they are already
  /// there (the home screen loads at midnight too).
  Future<void> onMidnight() async {
    final String? circleId = shownCircleId;
    final PatientClock? patient = shownPatient;
    if (circleId != null && patient != null) {
      await load(circleId, patient.zone);
    }
  }

  /// At the patient's next midnight, a real moment (a DST day is 23 or 25
  /// hours long).
  void scheduleMidnight() {
    midnight?.cancel();
    final PatientClock? patient = shownPatient;
    if (patient == null) return;
    final DateTime next = patient.momentOf(
      addDays(patient.today(), 1),
      '00:00',
    );
    midnight = Timer(next.difference(clock()), () => unawaited(onMidnight()));
  }
}
