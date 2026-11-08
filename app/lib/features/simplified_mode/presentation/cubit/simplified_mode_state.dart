import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported simplified day status values.
enum SimplifiedModeStatus { loading, ready, failure }

/// The patient's day as the simplified screens show it, at [now].
class SimplifiedModeState extends Equatable {
  SimplifiedModeState({
    required this.now,
    this.status = SimplifiedModeStatus.loading,
    this.day,
    this.messageKey,
    this.saving = false,
  });

  final SimplifiedModeStatus status;

  /// The last day read; kept while it is read again, so the screen does
  /// not blank out.
  final SimplifiedDay? day;

  /// The instant the statuses are worked out for; it moves each minute.
  final DateTime now;

  /// Why the last load or action failed: a key in assets/translations.
  final String? messageKey;

  /// A dose is being recorded.
  final bool saving;

  /// [day]'s tasks with their statuses at [now].
  late final TodaySchedule? schedule = switch (day) {
    final SimplifiedDay value => TodaySchedule.build(
      now: now,
      doses: value.doses,
      measurements: value.measurements,
      appointments: value.appointments,
    ),
    null => null,
  };

  SimplifiedModeState copyWith({
    SimplifiedModeStatus? status,
    SimplifiedDay? day,
    DateTime? now,
    String? messageKey,
    bool clearMessage = false,
    bool? saving,
  }) {
    return SimplifiedModeState(
      status: status ?? this.status,
      day: day ?? this.day,
      now: now ?? this.now,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [status, day, now, messageKey, saving];
}
