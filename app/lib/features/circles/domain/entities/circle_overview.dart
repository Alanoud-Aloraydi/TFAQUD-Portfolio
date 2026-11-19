export 'package:app/features/circles/domain/entities/circle_member.dart';
export 'package:app/features/circles/domain/entities/circle_pending_invitation.dart';
export 'package:app/features/circles/domain/entities/edit_access.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_pending_invitation.dart';
import 'package:equatable/equatable.dart';

/// People and pending invitations visible to a circle member.
class CircleOverview extends Equatable {
  CircleOverview({
    required this.name,
    required this.patientName,
    required this.patientIsYou,
    required this.patientUsesApp,
    this.patientAvatarCode,
    this.appMode,
    required this.patientBirthDate,
    required this.city,
    required this.canManage,
    this.canManageMembers = false,
    this.canHandOver = false,
    bool? canLeave,
    required List<CircleMember> members,
    required List<CirclePendingInvitation> pendingInvitations,
  }) : canLeave = canLeave ?? canManage,
       members = List.unmodifiable(members),
       pendingInvitations = List.unmodifiable(pendingInvitations);

  final String name;
  final String patientName;
  final bool patientIsYou;
  final bool patientUsesApp;
  final String? patientAvatarCode;

  /// The mode of the patient's app; null for a patient without an account.
  final CircleAppMode? appMode;
  final DateTime patientBirthDate;
  final String city;
  final bool canManage;

  /// Whether you lead the circle («قائد الدائرة»): only the leader removes
  /// members and says who edits what.
  final bool canManageMembers;

  /// Whether you may hand the leadership to another member: you lead, and
  /// the patient does not (a patient in the detailed mode always leads).
  final bool canHandOver;

  /// A manager, and a member whose editing is paused, may leave.
  final bool canLeave;
  final List<CircleMember> members;
  final List<CirclePendingInvitation> pendingInvitations;

  /// The patient themself; or a manager, when the patient has no account.
  /// A patient with an account in the circle chooses their own picture.
  /// The same people name the circle (one pen edits both).
  bool get canEditPatientPhoto =>
      patientIsYou || (canManage && !patientUsesApp);

  /// Leaving deletes the circle when the person leaving is its patient or
  /// its only member (the server's rule, `CareService.leave_circle`). A
  /// member with paused editing still counts as someone who stays. When the
  /// members changed meanwhile the server refuses and the tab reads the
  /// circle again.
  bool get leaveDeletesCircle =>
      patientIsYou ||
      members.where((CircleMember member) => member.holdsMembership).length <=
          1;

  @override
  List<Object?> get props => [
    name,
    patientName,
    patientIsYou,
    patientUsesApp,
    patientAvatarCode,
    appMode,
    patientBirthDate,
    city,
    canManage,
    canManageMembers,
    canHandOver,
    canLeave,
    members,
    pendingInvitations,
  ];
}
