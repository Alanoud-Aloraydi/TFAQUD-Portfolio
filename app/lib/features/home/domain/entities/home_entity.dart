import 'package:equatable/equatable.dart';

/// Summarizes the selected care circle for Home.
class CareCircleSummary extends Equatable {
  const CareCircleSummary({
    required this.id,
    required this.name,
    this.canManageMedications = false,
    this.patientAvatarCode,
  });

  final String id;
  final String name;
  final bool canManageMedications;
  final String? patientAvatarCode;

  @override
  List<Object?> get props => [
    id,
    name,
    canManageMedications,
    patientAvatarCode,
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
