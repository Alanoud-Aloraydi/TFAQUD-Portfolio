import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Holds the patient's day for every simplified screen: the home card, the
/// day's list, and the full-screen reminders read the same state.
/// [shownClock], when given, follows the day's patient, so every page reads
/// that patient's clock (see [ShownCircleClock]).
class SimplifiedModeCubit extends Cubit<SimplifiedModeState> {
  SimplifiedModeCubit(
    this._useCase, {
    DateTime Function()? clock,
    this._photoChanges,
    this._shownClock,
    Duration tick = const Duration(minutes: 1),
  }) : _clock = clock ?? DateTime.now,
       super(SimplifiedModeState(now: (clock ?? DateTime.now)())) {
    // Statuses follow the clock («التالي» becomes «فات موعده»), so the
    // state moves with it between reads of the server.
    _ticker = Timer.periodic(tick, (_) => _tick());
    // A member's new photo shows on the family row without a restart.
    _photoChanges?.addListener(_onPhotoChanged);
    // A task put off here, in the detailed mode or from its notification,
    // says when it comes again; it stops saying so once it came.
    _useCase.snoozes.addListener(_onSnoozed);
    _onSnoozed();
  }

  final SimplifiedModeUseCase _useCase;
  final DateTime Function() _clock;
  final Listenable? _photoChanges;
  final ShownCircleClock? _shownClock;
  late final Timer _ticker;
  int _revision = 0;
  bool _reminding = false;

  void _tick() {
    if (isClosed) return;
    emit(state.copyWith(now: _clock()));
  }

  void _onPhotoChanged() => unawaited(load());

  void _onSnoozed() {
    if (isClosed) return;
    emit(state.copyWith(snoozes: _useCase.snoozes.value));
  }

  /// Reads the day. A newer call wins over an older one still in flight.
  Future<void> load() async {
    final int revision = ++_revision;
    if (state.day == null) {
      emit(state.copyWith(status: SimplifiedModeStatus.loading));
    }
    final Result<SimplifiedDay, Failure> result = await _useCase.loadDay(
      _clock(),
    );
    if (isClosed || revision != _revision) return;
    result.when(
      (SimplifiedDay day) {
        _shownClock?.show(day.timeZone);
        emit(
          state.copyWith(
            status: SimplifiedModeStatus.ready,
            day: day,
            now: _clock(),
            clearMessage: true,
          ),
        );
        if (!_reminding) {
          _reminding = true;
          unawaited(_useCase.keepReminding(day));
        }
      },
      (Failure failure) => emit(
        state.copyWith(
          status: state.day == null
              ? SimplifiedModeStatus.failure
              : SimplifiedModeStatus.ready,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }

  /// The app came back to the front: the day and the reminders again.
  Future<void> resumed() async {
    await (load(), _useCase.refreshReminders()).wait;
  }

  /// Records [dose] as taken now. Returns the moment it was saved for, or
  /// null when it was not saved ([SimplifiedModeState.messageKey] says why).
  Future<DateTime?> takeDose(DoseOccurrence dose) async {
    final SimplifiedDay? day = state.day;
    if (day == null || state.saving) return null;
    emit(state.copyWith(saving: true, clearMessage: true));
    final DateTime takenAt = _clock();
    final Result<DoseRecord, Failure> result = await _useCase.takeDose(
      day.circleId,
      dose,
      takenAt,
    );
    if (isClosed) return null;
    final Failure? failure = result.tryGetError();
    // Recorded, it is no longer put off: the card shows it done.
    emit(state.copyWith(saving: false, messageKey: failure?.messageKey));
    // Saved or refused (someone else recorded it first), the day is read
    // again so the screen shows what the server holds.
    unawaited(load());
    return failure == null ? takenAt : null;
  }

  /// «ذكّرني لاحقًا» on [task], the dose or measurement the patient chose:
  /// it is reminded of again [after] from now, the same as in the detailed
  /// mode. A second press while one is being saved does nothing.
  Future<void> snooze({
    required TodayTask task,
    required Duration after,
  }) async {
    final SimplifiedDay? day = state.day;
    if (day == null || state.saving) return;
    emit(state.copyWith(saving: true));
    try {
      await _useCase.snooze(day.circleId, task, after);
    } finally {
      if (!isClosed) emit(state.copyWith(saving: false));
    }
  }

  /// «ذكّرني لاحقًا» pressed in a notification; false when [tap] is not
  /// that button.
  Future<bool> snoozeFromNotification(String tap) =>
      _useCase.snoozeFromNotification(tap);

  /// The message was shown; it is not shown again.
  void messageShown() => emit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() {
    _ticker.cancel();
    _photoChanges?.removeListener(_onPhotoChanged);
    _useCase.snoozes.removeListener(_onSnoozed);
    return super.close();
  }
}
