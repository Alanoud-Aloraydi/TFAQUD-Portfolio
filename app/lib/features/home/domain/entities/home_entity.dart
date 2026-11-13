import 'package:app/core/utils/patient_clock.dart';
import 'package:equatable/equatable.dart';

/// Summarizes the selected care circle for Home.
class CareCircleSummary extends Equatable {
  const CareCircleSummary({
    required this.id,
    required this.name,
    this.canManageMedications = false,
    bool? canManageMeasurements,
    bool? canManageAppointments,
    this.patientAvatarCode,
    this.isPatient = true,
    this.patientName,
    this.timeZone = defaultPatientZone,
    this.latitude,
    this.longitude,
  }) : canManageMeasurements = canManageMeasurements ?? canManageMedications,
       canManageAppointments = canManageAppointments ?? canManageMedications;

  final String id;
  final String name;

  /// Whether the signed-in account may add and change this circle's
  /// medicines. The circle's leader decides it for each member, area by
  /// area: the medicines, the measurements, the appointments.
  final bool canManageMedications;

  /// The same for the measurement plans; as [canManageMedications] when an
  /// older server does not say.
  final bool canManageMeasurements;

  /// The same for the appointments.
  final bool canManageAppointments;

  /// Whether the account edits at least one area: it may then also record
  /// a dose or a reading, put a task off, and write the visit sheet. A
  /// member with every area off only reads.
  bool get canRecord =>
      canManageMedications || canManageMeasurements || canManageAppointments;
  final String? patientAvatarCode;

  /// Whether the signed-in account is this circle's patient; the app then
  /// speaks to them as «أنت». True when an older server does not say.
  final bool isPatient;

  /// The patient's name, for the words someone caring for them reads
  /// («أدوية محمود الحالية»).
  final String? patientName;

  /// The IANA zone where the patient lives: every day and time of this
  /// circle is wall clock there ([clock]). [defaultPatientZone] when an
  /// older server does not say.
  final String timeZone;

  /// The patient's clock.
  PatientClock get clock => PatientClock(timeZone);

  /// Where the patient's city is, for its weather on «اليوم»; null for a
  /// city typed and not picked from the list.
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [
    id,
    name,
    canManageMedications,
    canManageMeasurements,
    canManageAppointments,
    patientAvatarCode,
    isPatient,
    latitude,
    longitude,
    patientName,
    timeZone,
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
