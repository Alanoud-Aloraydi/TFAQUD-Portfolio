import 'package:app/features/circles/domain/entities/edit_access.dart';
import 'package:equatable/equatable.dart';

/// Represents one member of a care circle.
class CircleMember extends Equatable {
  const CircleMember({
    required this.name,
    required this.isYou,
    this.isPatient = false,
    this.accountId,
    this.avatarCode,
    this.isManager = true,
    bool? canEdit,
    this.isLeader = false,
    this.access,
    this.phoneNumber,
  }) : canEdit = canEdit ?? isManager;

  final String name;
  final bool isYou;

  /// Whether this member is the patient of the circle («صاحب الملف»).
  final bool isPatient;
  final String? accountId;
  final String? avatarCode;
  final bool isManager;
  final bool canEdit;

  /// Whether this member leads the circle («قائد الدائرة»).
  final bool isLeader;

  /// What this member may edit, area by area; null from a server before
  /// the areas, where [canEdit] says it for all three ([editAccess]).
  final EditAccess? access;

  /// What this member may edit, area by area.
  EditAccess get editAccess => access ?? EditAccess.all(canEdit);

  /// So another member can call them; null for a patient with no account.
  final String? phoneNumber;

  /// A member the owner paused: still in the circle, reading only.
  bool get isViewOnly => !isManager && !isPatient;

  /// Whether the server holds a membership row for this person. The patient
  /// of a circle who manages nothing is listed but holds none.
  bool get holdsMembership => isManager || !isPatient;

  @override
  List<Object?> get props => [
    name,
    isYou,
    isPatient,
    accountId,
    avatarCode,
    isManager,
    canEdit,
    isLeader,
    access,
    phoneNumber,
  ];
}
