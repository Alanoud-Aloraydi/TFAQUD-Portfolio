import 'package:equatable/equatable.dart';
import 'package:app/core/utils/riyadh_time.dart';

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
  final AppointmentStatus status;
  final DateTime updatedAt;

  DateTime get scheduledAt {
    return riyadhScheduledAt(scheduledOn, time);
  }

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
