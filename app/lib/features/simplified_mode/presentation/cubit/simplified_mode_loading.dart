import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_writing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Reading the patient's day, and starting its reminders once.
mixin SimplifiedModeLoading on Cubit<SimplifiedModeState>, SimplifiedModeScope {
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
}
