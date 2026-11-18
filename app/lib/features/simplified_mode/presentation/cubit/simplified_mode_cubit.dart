import 'dart:async';

import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_following.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_loading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_scope.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_snoozing.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_writing.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the patient's day for every simplified screen: the home card, the
/// day's list, and the full-screen reminders read the same state.
/// [shownClock], when given, follows the day's patient, so every page reads
/// that patient's clock (see [ShownCircleClock]).
class SimplifiedModeCubit extends Cubit<SimplifiedModeState>
    with
        SimplifiedModeScope,
        SimplifiedModeFollowing,
        SimplifiedModeLoading,
        SimplifiedModeWriting,
        SimplifiedModeSnoozing {
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

  @override
  final SimplifiedModeUseCase useCase;
  @override
  final DateTime Function() clock;
  @override
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
}
