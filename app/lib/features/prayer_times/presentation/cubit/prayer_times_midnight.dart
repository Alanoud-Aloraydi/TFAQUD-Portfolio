import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/domain/usecases/prayer_times_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

enum PrayerTimesStatus { loading, ready, failure }

/// The patient's prayer times for today, as the screen shows them.
class PrayerTimesState extends Equatable {
  const PrayerTimesState({
    this.status = PrayerTimesStatus.loading,
    this.day,
    this.messageKey,
  });

  final PrayerTimesStatus status;
  final PrayerDay? day;
  final String? messageKey;

  @override
  List<Object?> get props => [status, day, messageKey];
}
