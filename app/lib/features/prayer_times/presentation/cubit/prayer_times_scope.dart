import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What every part of the prayer times cubit works on: the use case, the
/// clock, and what it last read and for whom.
mixin PrayerTimesScope on Cubit<PrayerTimesState> {
  PrayerTimesUseCase get repository;

  /// The current instant; tests control the day through it.
  DateTime Function() get clock;

  /// The circle whose times are shown.
  String? shownCircleId;

  /// The clock of that circle's patient.
  PatientClock? shownPatient;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// Fires at the patient's next midnight.
  Timer? midnight;

  /// The circle and day being read now, so the same read is not started
  /// twice.
  String? loadingKey;
}
