import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

enum SimplifiedMeasurementStatus { loading, ready, failure }

/// What the «تسجيل قياس» screen needs: the task this reading answers, if
/// it was opened from one, and the kinds a free reading can be.
class SimplifiedMeasurementState extends Equatable {
  const SimplifiedMeasurementState({
    this.task,
    this.status = SimplifiedMeasurementStatus.loading,
    this.saving = false,
    this.messageKey,
  });

  /// The task the screen was opened for (a reminder or a «اليوم» row);
  /// null when opened from «سجّل قياس», so the reading is a free one, as
  /// the detailed mode's sheet without an occurrence.
  final MeasurementOccurrence? task;
  final SimplifiedMeasurementStatus status;
  final bool saving;

  /// Why loading or saving failed: a key in assets/translations.
  final String? messageKey;

  /// The kinds that can be recorded: the task's own, else both, blood
  /// pressure first, as on the screen. Fixed normal ranges judge every
  /// reading, so a free one needs no target.
  List<MeasurementKind> get kinds => task != null
      ? <MeasurementKind>[task!.kind]
      : const <MeasurementKind>[MeasurementKind.bp, MeasurementKind.glucose];

  SimplifiedMeasurementState copyWith({
    SimplifiedMeasurementStatus? status,
    bool? saving,
    String? messageKey,
    bool clearMessage = false,
  }) {
    return SimplifiedMeasurementState(
      task: task,
      status: status ?? this.status,
      saving: saving ?? this.saving,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
    );
  }

  @override
  List<Object?> get props => [task, status, saving, messageKey];
}
