import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported simplified measurement status values.
enum SimplifiedMeasurementStatus { loading, ready, failure }

/// What the «تسجيل قياس» screen needs: the kinds that can be recorded and
/// today's tasks they may answer.
class SimplifiedMeasurementState extends Equatable {
  SimplifiedMeasurementState({
    this.status = SimplifiedMeasurementStatus.loading,
    List<MeasurementTarget> targets = const <MeasurementTarget>[],
    List<MeasurementOccurrence> occurrences = const <MeasurementOccurrence>[],
    this.saving = false,
    this.messageKey,
  }) : targets = List<MeasurementTarget>.unmodifiable(targets),
       occurrences = List<MeasurementOccurrence>.unmodifiable(occurrences);

  final SimplifiedMeasurementStatus status;
  final List<MeasurementTarget> targets;
  final List<MeasurementOccurrence> occurrences;
  final bool saving;

  /// Why loading or saving failed: a key in assets/translations.
  final String? messageKey;

  /// The kinds that can be recorded: a free reading needs a saved target,
  /// which a plan always has. Blood pressure first, as on the screen.
  List<MeasurementKind> get kinds => <MeasurementKind>[
    for (final MeasurementKind kind in const <MeasurementKind>[
      MeasurementKind.bp,
      MeasurementKind.glucose,
    ])
      if (targets.any((target) => target.kind == kind) ||
          occurrences.any((item) => item.kind == kind))
        kind,
  ];

  /// The task of [kind] a reading at [now] answers: the latest one not
  /// recorded that can be recorded now (its time came, or comes within the
  /// hour, the rule of every «اليوم» row); null for a free reading.
  MeasurementOccurrence? taskFor(MeasurementKind kind, DateTime now) =>
      occurrences
          .where(
            (item) =>
                item.kind == kind &&
                item.record == null &&
                isRecordableNow(
                  riyadhScheduledAt(item.scheduledOn, item.time),
                  riyadhNow(now),
                ),
          )
          .lastOrNull;

  SimplifiedMeasurementState copyWith({
    SimplifiedMeasurementStatus? status,
    bool? saving,
    String? messageKey,
    bool clearMessage = false,
  }) {
    return SimplifiedMeasurementState(
      status: status ?? this.status,
      targets: targets,
      occurrences: occurrences,
      saving: saving ?? this.saving,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
    );
  }

  @override
  List<Object?> get props => [status, targets, occurrences, saving, messageKey];
}
