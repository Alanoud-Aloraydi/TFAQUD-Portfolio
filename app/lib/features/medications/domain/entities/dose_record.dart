import 'package:app/features/medications/domain/entities/dose_outcome.dart';
import 'package:equatable/equatable.dart';

/// The server's record of one dose explicitly taken or skipped; a dose
/// with no record has not been answered yet.
class DoseRecord extends Equatable {
  const DoseRecord({
    required this.id,
    required this.outcome,
    required this.recordedAt,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
    this.recordedByAccountId,
    this.recordedByName,
    this.recordedByAvatarCode,
  });

  final String id;
  final DoseOutcome outcome;

  /// The real moment it was taken; null when skipped.
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;

  /// When the server saved it.
  final DateTime recordedAt;

  /// Who recorded it: null for a dose from before this was tracked.
  final String? recordedByAccountId;
  final String? recordedByName;
  final String? recordedByAvatarCode;

  @override
  List<Object?> get props => [
    id,
    outcome,
    takenAt,
    skipReasonCode,
    skipReasonNote,
    recordedAt,
    recordedByAccountId,
    recordedByName,
    recordedByAvatarCode,
  ];
}
