import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/domain/usecases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_midnight.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads the patient's today's prayer times for a circle, and again at the
/// patient's midnight. [clock] gives the current instant, so tests control
/// the day.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now,
      super(const PrayerTimesState());

  final PrayerTimesUseCase repository;
  final DateTime Function() clock;

  @override
  Future<void> close() async {
    midnight?.cancel();
    return super.close();
  }

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

  /// Reads [circleId]'s times once per day of its patient, who lives in
  /// the IANA [timeZone]; [refresh] reads them again anyway.
  ///
  /// A failed [refresh] keeps the times shown when they are still the
  /// patient's today; otherwise the state is a failure the page can retry.
  Future<void> load(
    String circleId,
    String timeZone, {
    bool refresh = false,
  }) async {
    final PatientClock patient = PatientClock(timeZone, clock: clock);
    shownPatient = patient;
    final DateTime now = patient.now();
    final key = '$circleId:${now.year}-${now.month}-${now.day}';
    if (!refresh && loadingKey == key) return;
    final PrayerDay? current = state.day;
    final bool sameCircle = shownCircleId == circleId;
    final bool haveToday =
        sameCircle &&
        current != null &&
        current.date.year == now.year &&
        current.date.month == now.month &&
        current.date.day == now.day;
    if (!refresh && haveToday) return;
    shownCircleId = circleId;
    final reading = ++revision;
    loadingKey = key;
    if (current == null || !sameCircle) emit(const PrayerTimesState());
    final result = await repository.getToday(circleId);
    if (reading == revision) loadingKey = null;
    if (isClosed || reading != revision) return;
    result.when(
      (day) =>
          emit(PrayerTimesState(status: PrayerTimesStatus.ready, day: day)),
      (failure) {
        if (haveToday) return;
        emit(
          PrayerTimesState(
            status: PrayerTimesStatus.failure,
            messageKey: failure.messageKey,
          ),
        );
      },
    );
    scheduleMidnight();
  }

  /// Reads the shown circle's times again.
  Future<void> reload() async {
    final String? circleId = shownCircleId;
    final PatientClock? patient = shownPatient;
    if (circleId != null && patient != null) {
      await load(circleId, patient.zone, refresh: true);
    }
  }
}
