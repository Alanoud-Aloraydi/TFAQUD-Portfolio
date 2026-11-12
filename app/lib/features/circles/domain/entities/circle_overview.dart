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

/// What a member may edit: the medicines, the measurements and the
/// appointments, each on its own. The circle's leader decides it.
class EditAccess extends Equatable {
  const EditAccess({
    required this.medications,
    required this.measurements,
    required this.appointments,
  });

  /// The same for all three.
  const EditAccess.all(bool allowed)
    : medications = allowed,
      measurements = allowed,
      appointments = allowed;

  /// The areas, as the API names them, in the order they show.
  static const List<String> areas = <String>[
    'medications',
    'measurements',
    'appointments',
  ];

  /// The `edit_access` of the API; [fallback] for each area it leaves out.
  factory EditAccess.fromJson(Object? json, {required bool fallback}) {
    final Map<String, dynamic> values = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    bool read(String area) => values[area] as bool? ?? fallback;
    return EditAccess(
      medications: read('medications'),
      measurements: read('measurements'),
      appointments: read('appointments'),
    );
  }

  final bool medications;
  final bool measurements;
  final bool appointments;

  /// Whether [area] («medications», …) may be edited.
  bool of(String area) => switch (area) {
    'medications' => medications,
    'measurements' => measurements,
    _ => appointments,
  };

  /// Whether at least one area may be edited.
  bool get any => medications || measurements || appointments;

  @override
  List<Object?> get props => [medications, measurements, appointments];
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
