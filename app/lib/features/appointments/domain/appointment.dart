import 'package:app/core/utils/patient_clock.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported appointment kind values.
enum AppointmentKind { followUp, test, imaging, remote, other }

/// Defines the supported appointment status values.
enum AppointmentStatus { scheduled, completed, cancelled }

/// Represents a scheduled care appointment.
class CareAppointment extends Equatable {
  const CareAppointment({
    required this.id,
    required this.specialty,
    required this.kind,
    required this.otherKind,
    required this.scheduledOn,
    required this.time,
    required this.place,
    required this.remoteMethod,
    required this.companions,
    required this.status,
    required this.updatedAt,
    this.createdByName,
    this.updatedByName,
  });

  final String id;
  final String specialty;
  final AppointmentKind kind;
  final String? otherKind;
  final DateTime scheduledOn;
  final String time;
  final String? place;
  final String? remoteMethod;
  final List<AppointmentCompanion> companions;

  /// The accounts going with the patient.
  Iterable<String> get companionIds =>
      companions.map((AppointmentCompanion companion) => companion.id);
  final AppointmentStatus status;
  final DateTime updatedAt;

  /// Who added or last changed it, for tracking; null when unavailable.
  final String? createdByName;
  final String? updatedByName;

  /// The visit's wall time where the patient lives, on the scale of
  /// [PatientClock.now].
  DateTime get scheduledAt => wallClockAt(scheduledOn, time);

  @override
  List<Object?> get props => [
    id,
    specialty,
    kind,
    otherKind,
    scheduledOn,
    time,
    place,
    remoteMethod,
    companions,
    status,
    updatedAt,
    createdByName,
    updatedByName,
  ];
}

/// Identifies a circle member accompanying an appointment.
class AppointmentCompanion extends Equatable {
  const AppointmentCompanion({
    required this.id,
    required this.name,
    this.avatarCode,
  });

  final String id;
  final String name;
  final String? avatarCode;

  @override
  List<Object?> get props => [id, name, avatarCode];
}

/// Holds editable appointment values before saving.
class AppointmentDraft extends Equatable {
  const AppointmentDraft({
    required this.specialty,
    required this.kind,
    required this.otherKind,
    required this.scheduledOn,
    required this.time,
    required this.place,
    required this.remoteMethod,
    required this.companionAccountIds,
  });

  final String specialty;
  final AppointmentKind kind;
  final String? otherKind;
  final DateTime scheduledOn;
  final String time;
  final String? place;
  final String? remoteMethod;
  final List<String> companionAccountIds;

  @override
  List<Object?> get props => [
    specialty,
    kind,
    otherKind,
    scheduledOn,
    time,
    place,
    remoteMethod,
    companionAccountIds,
  ];
}
