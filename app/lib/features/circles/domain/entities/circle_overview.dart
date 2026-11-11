import 'package:app/features/circles/domain/circle_app_mode.dart';
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
    required List<CircleMember> members,
    required List<CirclePendingInvitation> pendingInvitations,
  }) : members = List.unmodifiable(members),
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
  final bool canManageMembers;
  final List<CircleMember> members;
  final List<CirclePendingInvitation> pendingInvitations;

  /// The patient themself; or a manager, when the patient has no account.
  /// A patient with an account in the circle chooses their own picture.
  bool get canEditPatientPhoto =>
      patientIsYou || (canManage && !patientUsesApp);

  /// Leaving deletes the circle when the person leaving is its patient or
  /// its only manager (the server's rule, `CareService.leave_circle`). The
  /// tab asks to delete instead of to leave; when the members changed
  /// meanwhile the server refuses and the tab reads the circle again.
  bool get leaveDeletesCircle =>
      patientIsYou ||
      members.where((CircleMember member) => member.isManager).length <= 1;

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
    members,
    pendingInvitations,
  ];
}

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

  /// So another member can call them; null for a patient with no account.
  final String? phoneNumber;

  @override
  List<Object?> get props => [
    name,
    isYou,
    isPatient,
    accountId,
    avatarCode,
    isManager,
    canEdit,
    phoneNumber,
  ];
}

/// Tracks an invitation awaiting acceptance.
class CirclePendingInvitation extends Equatable {
  const CirclePendingInvitation({
    required this.id,
    required this.phoneNumber,
    required this.createdAt,
    this.lastSentAt,
  });

  final String id;
  final String phoneNumber;
  final DateTime createdAt;

  /// When it was last sent: later than [createdAt] after «إعادة الإرسال».
  final DateTime? lastSentAt;

  /// The time the row shows in «أُرسلت قبل ...».
  DateTime get sentAt => lastSentAt ?? createdAt;

  @override
  List<Object?> get props => [id, phoneNumber, createdAt, lastSentAt];
}
