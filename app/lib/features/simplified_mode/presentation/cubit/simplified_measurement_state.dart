import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported simplified measurement status values.
enum SimplifiedMeasurementStatus { loading, ready, failure }

/// What the «تسجيل قياس» screen needs: the task this reading answers, if
/// it was opened from one, and the kinds a free reading can be.
class SimplifiedMeasurementState extends Equatable {
  SimplifiedMeasurementState({
    this.task,
    this.status = SimplifiedMeasurementStatus.loading,
    List<MeasurementTarget> targets = const <MeasurementTarget>[],
    this.saving = false,
    this.messageKey,
  }) : targets = List<MeasurementTarget>.unmodifiable(targets);

  /// The task the screen was opened for (a reminder or a «اليوم» row);
  /// null when opened from «سجّل قياس», so the reading is a free one, as
  /// the detailed mode's sheet without an occurrence.
  final MeasurementOccurrence? task;
  final SimplifiedMeasurementStatus status;
  final List<MeasurementTarget> targets;
  final bool saving;

  /// Why loading or saving failed: a key in assets/translations.
  final String? messageKey;

  /// The kinds that can be recorded: the task's own, else those with a
  /// saved target (the server refuses a free reading without one). Blood
  /// pressure first, as on the screen.
  List<MeasurementKind> get kinds => task != null
      ? <MeasurementKind>[task!.kind]
      : <MeasurementKind>[
          for (final MeasurementKind kind in const <MeasurementKind>[
            MeasurementKind.bp,
            MeasurementKind.glucose,
          ])
            if (targets.any((target) => target.kind == kind)) kind,
        ];

  SimplifiedMeasurementState copyWith({
    SimplifiedMeasurementStatus? status,
    List<MeasurementTarget>? targets,
    bool? saving,
    String? messageKey,
    bool clearMessage = false,
  }) {
    return SimplifiedMeasurementState(
      task: task,
      status: status ?? this.status,
      targets: targets ?? this.targets,
      saving: saving ?? this.saving,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
    );
  }

  @override
  List<Object?> get props => [task, status, targets, saving, messageKey];
}
