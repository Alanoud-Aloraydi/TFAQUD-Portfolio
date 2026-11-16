import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
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
    this.saved,
    this.recent = const <MeasurementReading>[],
  });

  /// The task the screen was opened for (a reminder or a «اليوم» row);
  /// null when opened from «سجّل قياس», so the reading is a free one, as
  /// the detailed mode's sheet without an occurrence.
  final MeasurementOccurrence? task;
  final SimplifiedMeasurementStatus status;
  final bool saving;

  /// Why loading or saving failed: a key in assets/translations.
  final String? messageKey;

  /// The patient's last readings, newest first, both kinds together.
  final List<MeasurementReading> recent;

  /// The reading the server wrote, once one was saved. It carries the
  /// level the server judged it at, which is what «تم» then says.
  final MeasurementReading? saved;

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
    MeasurementReading? saved,
    List<MeasurementReading>? recent,
  }) {
    return SimplifiedMeasurementState(
      task: task,
      recent: recent ?? this.recent,
      status: status ?? this.status,
      saving: saving ?? this.saving,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [task, status, saving, messageKey, saved, recent];
}
