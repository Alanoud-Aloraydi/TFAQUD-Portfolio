import 'dart:async';

import 'package:app/app/services/shown_circle_clock.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_loading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// The answers the patient gives on the day: a dose taken or skipped, a
/// visit attended.
mixin SimplifiedModeWriting
    on Cubit<SimplifiedModeState>, SimplifiedModeScope, SimplifiedModeLoading {
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
}

/// Putting a task off with «ذكّرني لاحقًا».
mixin SimplifiedModeSnoozing
    on Cubit<SimplifiedModeState>, SimplifiedModeScope {
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

/// What the simplified day's cubit hands to the mixins that hold its
/// behaviour: the use case, the clock and the clock of the day's patient.
mixin SimplifiedModeScope on Cubit<SimplifiedModeState> {
  /// Reads and writes the patient's day.
  SimplifiedModeUseCase get useCase;

  /// Now, as the cubit tells it; replaced by tests.
  DateTime Function() get clock;

  /// Follows the day's patient, when one was given.
  ShownCircleClock? get shownClock;
}
