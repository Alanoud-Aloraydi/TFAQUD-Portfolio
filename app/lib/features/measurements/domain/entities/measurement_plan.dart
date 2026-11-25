import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_version.dart';
import 'package:equatable/equatable.dart';

/// Holds a recurring measurement schedule.
class MeasurementPlan extends Equatable {
  const MeasurementPlan({
    required this.id,
    required this.kind,
    required this.version,
    required this.history,
    this.pendingVersion,
    this.stoppedAt,
    this.createdByAccountId,
    this.createdByName,
    this.createdByAvatarCode,
    this.lastEditedByName,
    this.lastEditedByAccountId,
    this.lastEditedByAvatarCode,
  });

  final String id;
  final MeasurementKind kind;
  final MeasurementVersion version;
  final MeasurementVersion? pendingVersion;
  final List<MeasurementVersion> history;
  final DateTime? stoppedAt;

  /// Who added this plan, for tracking; null when it predates this field.
  final String? createdByAccountId;
  final String? createdByName;
  final String? createdByAvatarCode;

  /// Who made the version in effect now; same person as [createdByName]
  /// unless the plan was revised since, or null when it predates this field.
  final String? lastEditedByName;
  final String? lastEditedByAccountId;
  final String? lastEditedByAvatarCode;

  factory MeasurementPlan.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    final lastEditedBy = json['last_edited_by'] as Map<String, dynamic>?;
    return MeasurementPlan(
      id: json['id'] as String,
      kind: measurementKindFromWire(json['kind']),
      version: MeasurementVersion.fromJson(
        json['version'] as Map<String, dynamic>,
      ),
      pendingVersion: json['pending_version'] == null
          ? null
          : MeasurementVersion.fromJson(
              json['pending_version'] as Map<String, dynamic>,
            ),
      history: (json['history'] as List<dynamic>)
          .map(
            (value) =>
                MeasurementVersion.fromJson(value as Map<String, dynamic>),
          )
          .toList(),
      stoppedAt: json['stopped_at'] == null
          ? null
          : DateTime.parse(json['stopped_at'] as String),
      createdByAccountId: createdBy?['account_id'] as String?,
      createdByName: createdBy?['name'] as String?,
      createdByAvatarCode: createdBy?['avatar_code'] as String?,
      lastEditedByName: lastEditedBy?['name'] as String?,
      lastEditedByAccountId: lastEditedBy?['account_id'] as String?,
      lastEditedByAvatarCode: lastEditedBy?['avatar_code'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    version,
    pendingVersion,
    history,
    stoppedAt,
    createdByAccountId,
    createdByName,
    createdByAvatarCode,
    lastEditedByName,
    lastEditedByAccountId,
    lastEditedByAvatarCode,
  ];
}

/// Reads a measurement plan's [PlanStatus] for a given day. A measurement
/// plan has no end date, so it never completes: it is stopped or it goes on.
extension MeasurementPlanStatus on MeasurementPlan {
  PlanStatus statusOn(DateTime day) {
    if (stoppedAt != null) return PlanStatus.stopped;
    if (version.effectiveFromOn.isAfter(day)) return PlanStatus.scheduled;
    return PlanStatus.active;
  }
}
