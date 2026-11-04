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
    required List<CircleMember> members,
    required List<CirclePendingInvitation> pendingInvitations,
  }) : members = List.unmodifiable(members),
       pendingInvitations = List.unmodifiable(pendingInvitations);

  final String name;
  final String patientName;
  final bool patientIsYou;
  final bool patientUsesApp;
  final String? patientAvatarCode;
  final String? appMode;
  final DateTime patientBirthDate;
  final String city;
  final bool canManage;
  final List<CircleMember> members;
  final List<CirclePendingInvitation> pendingInvitations;

  bool get canEditPatientPhoto =>
      patientIsYou ||
      (canManage && (!patientUsesApp || appMode == 'simplified'));

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
  });

  final String name;
  final bool isYou;

  /// Whether this member is the patient of the circle («صاحب الملف»).
  final bool isPatient;
  final String? accountId;
  final String? avatarCode;
  final bool isManager;

  @override
  List<Object?> get props => [
    name,
    isYou,
    isPatient,
    accountId,
    avatarCode,
    isManager,
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
