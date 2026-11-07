import 'package:app/features/measurements/domain/measurement.dart';
import 'package:equatable/equatable.dart';

enum SimplifiedMeasurementStatus { loading, ready, failure }

enum SimplifiedMeasurementSaveStatus { idle, saving }

/// Holds the simplified measurement-recording flow's presentation state:
/// which kinds have an active plan (for the type-selection skip), today's
/// unrecorded occurrence per kind (so saving resolves it instead of
/// creating an unrelated free reading), and the save action's own status.
class SimplifiedMeasurementState extends Equatable {
  const SimplifiedMeasurementState({
    this.status = SimplifiedMeasurementStatus.loading,
    this.targets = const [],
    this.occurrences = const [],
    this.saveStatus = SimplifiedMeasurementSaveStatus.idle,
    this.errorKey,
  });

  final SimplifiedMeasurementStatus status;
  final List<MeasurementTarget> targets;
  final List<MeasurementOccurrence> occurrences;
  final SimplifiedMeasurementSaveStatus saveStatus;
  final String? errorKey;

  MeasurementTarget? targetFor(MeasurementKind kind) {
    for (final target in targets) {
      if (target.kind == kind) return target;
    }
    return null;
  }

  /// Today's due or missed task for [kind], not yet recorded; null when
  /// nothing is scheduled right now, so saving starts a free reading.
  MeasurementOccurrence? occurrenceFor(MeasurementKind kind) {
    for (final occurrence in occurrences) {
      if (occurrence.kind == kind &&
          occurrence.record == null &&
          (occurrence.status == MeasurementStatus.due ||
              occurrence.status == MeasurementStatus.missed)) {
        return occurrence;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    status,
    targets,
    occurrences,
    saveStatus,
    errorKey,
  ];
}
