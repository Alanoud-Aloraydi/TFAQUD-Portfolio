import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_scope.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
