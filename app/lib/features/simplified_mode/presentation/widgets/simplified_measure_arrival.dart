import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';

/// A load or a save that has just finished and left something new to show.
bool simplifiedMeasureSettled(
  SimplifiedMeasurementState before,
  SimplifiedMeasurementState after,
) =>
    (after.status == SimplifiedMeasurementStatus.ready &&
        before.status != SimplifiedMeasurementStatus.ready) ||
    (after.messageKey != null &&
        after.messageKey != before.messageKey &&
        after.status == SimplifiedMeasurementStatus.ready);

/// What that finished load means for [form]: the first one chooses the
/// kind and its conditions, a later one only carries a message.
void simplifiedMeasureArrived(
  SimplifiedMeasureForm form,
  SimplifiedMeasurementState state,
) {
  if (!form.started) {
    // Loaded: the task's kind, else the first kind that can be read.
    form.started = true;
    form.show(state, form.kind ?? state.kinds.firstOrNull);
  } else {
    form.errorKey = state.messageKey;
  }
}
