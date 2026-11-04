import 'dart:async';

import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates prayer times actions and UI state.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit(this._repository) : super(const PrayerTimesState());

  final PrayerTimesRepository _repository;
  String? _circleId;
  int _revision = 0;
  Timer? _midnight;
  String? _loadingKey;

  Future<void> load(String circleId, {bool refresh = false}) async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final key = '$circleId:${now.year}-${now.month}-${now.day}';
    if (!refresh && _loadingKey == key) return;
    final current = state.day;
    final previousCircleId = _circleId;
    if (!refresh &&
        _circleId == circleId &&
        current != null &&
        current.date.year == now.year &&
        current.date.month == now.month &&
        current.date.day == now.day) {
      return;
    }
    _circleId = circleId;
    final revision = ++_revision;
    _loadingKey = key;
    if (current == null || previousCircleId != circleId) {
      emit(const PrayerTimesState());
    }
    final result = await _repository.getToday(circleId);
    if (revision == _revision) _loadingKey = null;
    if (isClosed || revision != _revision) return;
    result.when(
      (day) =>
          emit(PrayerTimesState(status: PrayerTimesStatus.ready, day: day)),
      (failure) => emit(
        PrayerTimesState(
          status: PrayerTimesStatus.failure,
          messageKey: failure.messageKey,
        ),
      ),
    );
    _scheduleMidnight();
  }

  Future<void> reload() async {
    if (_circleId != null) await load(_circleId!, refresh: true);
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final next = DateTime.utc(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), () => unawaited(reload()));
  }

  @override
  Future<void> close() async {
    _midnight?.cancel();
    return super.close();
  }
}
