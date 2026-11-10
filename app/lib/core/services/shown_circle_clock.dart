import 'package:app/core/utils/patient_clock.dart';
import 'package:flutter/foundation.dart';

/// The [PatientClock] of the circle on screen, which [PatientClockScope]
/// gives every page from the app's root (routes opened on the root
/// navigator included).
///
/// Written by whoever chooses the circle shown: the detailed home's
/// `HomeCubit` and the simplified mode's `SimplifiedModeCubit`. Until one
/// does (sign-in, onboarding) it is [defaultPatientZone]'s clock.
class ShownCircleClock extends ValueNotifier<PatientClock> {
  ShownCircleClock() : super(PatientClock(defaultPatientZone));

  /// Shows the circle whose patient lives in the IANA [zone].
  void show(String zone) {
    if (value.zone != zone) value = PatientClock(zone);
  }
}
