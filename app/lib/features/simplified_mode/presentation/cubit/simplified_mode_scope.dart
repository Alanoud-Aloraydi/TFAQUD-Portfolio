import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
