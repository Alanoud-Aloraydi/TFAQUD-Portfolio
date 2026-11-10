import 'dart:async';

import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads the patient's today's prayer times for a circle, and again at the
/// patient's midnight. [clock] gives the current instant, so tests control
/// the day.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const PrayerTimesState());

  final PrayerTimesRepository _repository;
  final DateTime Function() _clock;
  String? _circleId;
  PatientClock? _patient;
  int _revision = 0;
  Timer? _midnight;
  String? _loadingKey;

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
    final PatientClock patient = PatientClock(timeZone, clock: _clock);
    _patient = patient;
    final DateTime now = patient.now();
    final key = '$circleId:${now.year}-${now.month}-${now.day}';
    if (!refresh && _loadingKey == key) return;
    final PrayerDay? current = state.day;
    final bool sameCircle = _circleId == circleId;
    final bool haveToday =
        sameCircle &&
        current != null &&
        current.date.year == now.year &&
        current.date.month == now.month &&
        current.date.day == now.day;
    if (!refresh && haveToday) return;
    _circleId = circleId;
    final revision = ++_revision;
    _loadingKey = key;
    if (current == null || !sameCircle) emit(const PrayerTimesState());
    final result = await _repository.getToday(circleId);
    if (revision == _revision) _loadingKey = null;
    if (isClosed || revision != _revision) return;
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
    _scheduleMidnight();
  }

  /// Reads the shown circle's times again.
  Future<void> reload() async {
    final String? circleId = _circleId;
    final PatientClock? patient = _patient;
    if (circleId != null && patient != null) {
      await load(circleId, patient.zone, refresh: true);
    }
  }

  /// A new day of the patient: reads the times unless they are already
  /// there (the home screen loads at midnight too).
  Future<void> _onMidnight() async {
    final String? circleId = _circleId;
    final PatientClock? patient = _patient;
    if (circleId != null && patient != null) {
      await load(circleId, patient.zone);
    }
  }

  /// At the patient's next midnight, a real moment (a DST day is 23 or 25
  /// hours long).
  void _scheduleMidnight() {
    _midnight?.cancel();
    final PatientClock? patient = _patient;
    if (patient == null) return;
    final DateTime midnight = patient.momentOf(
      addDays(patient.today(), 1),
      '00:00',
    );
    _midnight = Timer(
      midnight.difference(_clock()),
      () => unawaited(_onMidnight()),
    );
  }

  @override
  Future<void> close() async {
    _midnight?.cancel();
    return super.close();
  }
}
