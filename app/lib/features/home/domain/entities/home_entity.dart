import 'package:equatable/equatable.dart';

/// Summarizes the selected care circle for Home.
class CareCircleSummary extends Equatable {
  const CareCircleSummary({
    required this.id,
    required this.name,
    this.canManageMedications = false,
    this.patientAvatarCode,
    this.isPatient = true,
    this.patientName,
  });

  final String id;
  final String name;
  final bool canManageMedications;
  final String? patientAvatarCode;

  /// Whether the signed-in account is this circle's patient; the app then
  /// speaks to them as «أنت». True when an older server does not say.
  final bool isPatient;

  /// The patient's name, for the words someone caring for them reads
  /// («أدوية محمود الحالية»).
  final String? patientName;

  @override
  List<Object?> get props => [
    id,
    name,
    canManageMedications,
    patientAvatarCode,
    isPatient,
    patientName,
  ];
}

/// Represents home domain data.
class HomeEntity extends Equatable {
  HomeEntity({
    required this.accountId,
    required this.displayName,
    required this.profileComplete,
    this.avatarCode,
    required List<CareCircleSummary> circles,
  }) : circles = List.unmodifiable(circles);

  final String accountId;
  final String? displayName;
  final bool profileComplete;
  final String? avatarCode;
  final List<CareCircleSummary> circles;

  @override
  List<Object?> get props => [
    accountId,
    displayName,
    profileComplete,
    avatarCode,
    circles,
  ];
}
