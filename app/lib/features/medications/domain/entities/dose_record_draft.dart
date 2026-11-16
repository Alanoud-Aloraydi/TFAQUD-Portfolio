import 'package:app/features/medications/domain/entities/dose_outcome.dart';
import 'package:equatable/equatable.dart';

/// The answer to a dose before it is sent: taken at [takenAt] (a real
/// moment, sent in UTC), or skipped with an optional reason.
class DoseRecordDraft extends Equatable {
  const DoseRecordDraft({
    required this.outcome,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
  });

  final DoseOutcome outcome;
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;

  /// The body of `PUT medication-dose-records/{schedule}/{day}`.
  Map<String, Object?> toJson() => {
    'outcome': outcome.name,
    'taken_at': takenAt?.toUtc().toIso8601String(),
    'skip_reason_code': skipReasonCode,
    'skip_reason_note': skipReasonNote,
  };

  @override
  List<Object?> get props => [outcome, takenAt, skipReasonCode, skipReasonNote];
}
