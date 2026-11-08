import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Holds the patient's day for every simplified screen: the home card, the
/// day's list, and the full-screen reminders read the same state.
class SimplifiedModeCubit extends Cubit<SimplifiedModeState> {
  SimplifiedModeCubit(
    this._useCase, {
    DateTime Function()? clock,
    this._photoChanges,
    Duration tick = const Duration(minutes: 1),
  }) : _clock = clock ?? DateTime.now,
       super(SimplifiedModeState(now: (clock ?? DateTime.now)())) {
    // Statuses follow the clock («التالي» becomes «فات موعده»), so the
    // state moves with it between reads of the server.
    _ticker = Timer.periodic(tick, (_) => _tick());
    // A member's new photo shows on the family row without a restart.
    _photoChanges?.addListener(_onPhotoChanged);
  }

  final SimplifiedModeUseCase _useCase;
  final DateTime Function() _clock;
  final Listenable? _photoChanges;
  late final Timer _ticker;
  int _revision = 0;
  bool _reminding = false;

  void _tick() {
    if (!isClosed) emit(state.copyWith(now: _clock()));
  }

  void _onPhotoChanged() => unawaited(load());

  /// Reads the day. A newer call wins over an older one still in flight.
  Future<void> load() async {
    final int revision = ++_revision;
    if (state.day == null) {
      emit(state.copyWith(status: SimplifiedModeStatus.loading));
    }
    final DateTime now = _clock();
    final Result<SimplifiedDay, Failure> result = await _useCase.loadDay(now);
    if (isClosed || revision != _revision) return;
    result.when(
      (SimplifiedDay day) {
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
    emit(state.copyWith(saving: false, messageKey: failure?.messageKey));
    // Saved or refused (someone else recorded it first), the day is read
    // again so the screen shows what the server holds.
    unawaited(load());
    return failure == null ? takenAt : null;
  }

  /// Reminds of the task again [after] from now.
  Future<void> snooze({
    required SnoozedTask task,
    required String title,
    required String body,
    required Duration after,
  }) async {
    final SimplifiedDay? day = state.day;
    if (day == null) return;
    await _useCase.snooze(
      circleId: day.circleId,
      task: task,
      title: title,
      body: body,
      after: after,
    );
  }

  /// «ذكّرني لاحقًا» pressed in a notification; false when [tap] is not
  /// that button.
  Future<bool> snoozeFromNotification(String tap) =>
      _useCase.snoozeFromNotification(tap);

  void messageShown() => emit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() {
    _ticker.cancel();
    _photoChanges?.removeListener(_onPhotoChanged);
    return super.close();
  }
}
