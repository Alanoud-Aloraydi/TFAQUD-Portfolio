import 'package:app/features/medications/domain/entities/medication_last_record.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/medications/domain/entities/medication_last_record.dart';
export 'package:app/features/medications/domain/entities/medication_plan_draft.dart';
export 'package:app/features/medications/domain/entities/medication_version.dart';

/// Holds a medication treatment and its revisions.
class MedicationPlan extends Equatable {
  const MedicationPlan({
    required this.id,
    required this.createdAt,
    required this.version,
    this.pendingVersion,
    this.discontinuedAt,
    this.lastRecord,
    this.history = const [],
    this.createdByAccountId,
    this.createdByName,
    this.createdByAvatarCode,
    this.lastEditedByName,
    this.lastEditedByAccountId,
    this.lastEditedByAvatarCode,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? discontinuedAt;
  final MedicationVersion version;
  final MedicationVersion? pendingVersion;
  final MedicationLastRecord? lastRecord;
  final List<MedicationVersion> history;

  /// Who added this plan, for tracking; null when it predates this field.
  final String? createdByAccountId;
  final String? createdByName;
  final String? createdByAvatarCode;

  /// Who made the version in effect now; same person as [createdByName]
  /// unless the plan was revised since, or null when it predates this field.
  final String? lastEditedByName;
  final String? lastEditedByAccountId;
  final String? lastEditedByAvatarCode;

  bool isPreviousOn(DateTime day) =>
      discontinuedAt != null ||
      (version.endsOn != null && version.endsOn!.isBefore(day));

  bool isScheduledOn(DateTime day) => version.effectiveFromOn.isAfter(day);

  @override
  List<Object?> get props => [
    id,
    createdAt,
    discontinuedAt,
    version,
    pendingVersion,
    lastRecord,
    history,
    createdByAccountId,
    createdByName,
    createdByAvatarCode,
    lastEditedByName,
    lastEditedByAccountId,
    lastEditedByAvatarCode,
  ];
}
