import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:equatable/equatable.dart';

/// The simplified home screen's three visual states, plus the states
/// around loading it.
enum SimplifiedHomeStatus { loading, due, missed, done, error }

/// The one dose or measurement the home screen shows: the task due now,
/// or, when nothing is due, the most recent one missed today.
class SimplifiedHomeTask extends Equatable {
  SimplifiedHomeTask.medication(DoseOccurrence occurrence)
    : label = occurrence.name,
      time = occurrence.time,
      doseOccurrence = occurrence,
      measurementOccurrence = null;

  SimplifiedHomeTask.measurement(MeasurementOccurrence occurrence)
    : label = null,
      time = occurrence.time,
      doseOccurrence = null,
      measurementOccurrence = occurrence;

  /// The medicine name; null for a measurement task, whose label comes from
  /// its [MeasurementOccurrence.kind] instead.
  final String? label;
  final String time;
  final DoseOccurrence? doseOccurrence;
  final MeasurementOccurrence? measurementOccurrence;

  @override
  List<Object?> get props => [
    label,
    time,
    doseOccurrence,
    measurementOccurrence,
  ];
}

/// Holds the simplified home screen's presentation state.
class SimplifiedHomeState extends Equatable {
  const SimplifiedHomeState({
    this.status = SimplifiedHomeStatus.loading,
    this.greetingName,
    this.greetingIsEvening = false,
    this.task,
    this.members = const [],
    this.circleId,
  });

  final SimplifiedHomeStatus status;
  final String? greetingName;

  /// Whether the Riyadh wall clock reads noon or later when the screen
  /// loaded, so the greeting says "مساء الخير" instead of "صباح الخير".
  final bool greetingIsEvening;

  /// The task shown for [SimplifiedHomeStatus.due] or
  /// [SimplifiedHomeStatus.missed]; null otherwise.
  final SimplifiedHomeTask? task;
  final List<CircleMember> members;
  final String? circleId;

  @override
  List<Object?> get props => [
    status,
    greetingName,
    greetingIsEvening,
    task,
    members,
    circleId,
  ];
}
