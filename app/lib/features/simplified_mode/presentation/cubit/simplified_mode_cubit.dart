import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/utils/shown_circle_clock.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
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
    this.useCase, {
    DateTime Function()? clock,
    this._photoChanges,
    this.shownClock,
    Duration tick = const Duration(minutes: 1),
  }) : clock = clock ?? DateTime.now,
       super(SimplifiedModeState(now: (clock ?? DateTime.now)())) {
    // Statuses follow the clock («التالي» becomes «فات موعده»), so the
    // state moves with it between reads of the server.
    _ticker = Timer.periodic(tick, (_) => followClock());
    // A member's new photo shows on the family row without a restart.
    _photoChanges?.addListener(_onPhotoChanged);
    // A task put off here, in the detailed mode or from its notification,
    // says when it comes again; it stops saying so once it came.
    useCase.snoozes.addListener(followSnoozes);
    followSnoozes();
  }

  final SimplifiedModeUseCase useCase;
  final DateTime Function() clock;
  final ShownCircleClock? shownClock;
  final Listenable? _photoChanges;
  late final Timer _ticker;

  void _onPhotoChanged() => unawaited(load());

  /// The message was shown; it is not shown again.
  void messageShown() => emit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() {
    _ticker.cancel();
    _photoChanges?.removeListener(_onPhotoChanged);
    useCase.snoozes.removeListener(followSnoozes);
    return super.close();
  }

  /// Moves the state's instant to now.
  void followClock() {
    if (isClosed) return;
    emit(state.copyWith(now: clock()));
  }

  /// Takes the tasks put off, as the use case holds them now.
  void followSnoozes() {
    if (isClosed) return;
    emit(state.copyWith(snoozes: useCase.snoozes.value));
  }

  int _revision = 0;
  bool _reminding = false;

  /// Reads the day. A newer call wins over an older one still in flight.
  Future<void> load() async {
    final int revision = ++_revision;
    if (state.day == null) {
      emit(state.copyWith(status: SimplifiedModeStatus.loading));
    }
    final Result<SimplifiedDay, Failure> result = await useCase.loadDay(
      clock(),
    );
    if (isClosed || revision != _revision) return;
    result.when(
      (SimplifiedDay day) {
        shownClock?.show(day.timeZone);
        emit(
          state.copyWith(
            status: SimplifiedModeStatus.ready,
            day: day,
            now: clock(),
            clearMessage: true,
          ),
        );
        if (!_reminding) {
          _reminding = true;
          unawaited(useCase.keepReminding(day));
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
    await (load(), useCase.refreshReminders()).wait;
  }

  /// Records [dose] as taken now. Returns the moment it was saved for, or
  /// null when it was not saved ([SimplifiedModeState.messageKey] says why).
  Future<DateTime?> takeDose(DoseOccurrence dose) async {
    final DateTime takenAt = clock();
    final bool saved = await _write(
      (day) => useCase.takeDose(day.circleId, dose, takenAt),
    );
    return saved ? takenAt : null;
  }

  /// «لم آخذها» on [dose], with [reason] when the patient named one and
  /// the [note] written for «سبب آخر». Returns whether it was written.
  Future<bool> skipDose(
    DoseOccurrence dose,
    DoseSkipReason? reason, {
    String? note,
  }) =>
      _write((day) => useCase.skipDose(day.circleId, dose, reason, note: note));

  /// «حضرت» on [visit], the patient's own appointment, from an hour
  /// before its time. Returns whether it was written.
  Future<bool> attendAppointment(CareAppointment visit) =>
      _write((day) => useCase.attendAppointment(day.circleId, visit));

  /// Runs [write] on the day while the answers wait, and says whether it
  /// was written ([SimplifiedModeState.messageKey] says why not). Saved or
  /// refused (someone else recorded it first), the day is read again so
  /// the screen shows what the server holds.
  Future<bool> _write<T extends Object>(
    Future<Result<T, Failure>> Function(SimplifiedDay day) write,
  ) async {
    final SimplifiedDay? day = state.day;
    if (day == null || state.saving) return false;
    emit(state.copyWith(saving: true, clearMessage: true));
    final Result<T, Failure> result = await write(day);
    if (isClosed) return false;
    final Failure? failure = result.tryGetError();
    emit(state.copyWith(saving: false, messageKey: failure?.messageKey));
    unawaited(load());
    return failure == null;
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
      await useCase.snooze(day.circleId, task, after);
    } finally {
      if (!isClosed) emit(state.copyWith(saving: false));
    }
  }

  /// «ذكّرني لاحقًا» pressed in a notification; false when [tap] is not
  /// that button.
  Future<bool> snoozeFromNotification(String tap) =>
      useCase.snoozeFromNotification(tap);
}
