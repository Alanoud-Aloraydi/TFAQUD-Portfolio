import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';

/// Changing a few fields of the patient's day state.
extension SimplifiedModeStateCopy on SimplifiedModeState {
  /// A copy with the given fields; [clearMessage] drops [messageKey].
  SimplifiedModeState copyWith({
    SimplifiedModeStatus? status,
    SimplifiedDay? day,
    DateTime? now,
    String? messageKey,
    bool clearMessage = false,
    bool? saving,
    Map<String, TaskSnooze>? snoozes,
  }) {
    return SimplifiedModeState(
      status: status ?? this.status,
      day: day ?? this.day,
      now: now ?? this.now,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
      saving: saving ?? this.saving,
      snoozes: snoozes ?? this.snoozes,
    );
  }
}
