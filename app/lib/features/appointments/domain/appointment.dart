import 'package:equatable/equatable.dart';

enum AppointmentKind { followUp, test, imaging, remote }

enum AppointmentStatus { scheduled, completed, cancelled }

class CareAppointment extends Equatable {
  const CareAppointment({
    required this.id,
    required this.specialty,
    required this.kind,
    required this.scheduledOn,
    required this.time,
    required this.place,
    required this.remoteMethod,
    required this.companionAccountId,
    required this.companionName,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String specialty;
  final AppointmentKind kind;
  final DateTime scheduledOn;
  final String time;
  final String? place;
  final String? remoteMethod;
  final String companionAccountId;
  final String companionName;
  final AppointmentStatus status;
  final DateTime updatedAt;

  DateTime get scheduledAt {
    final parts = time.split(':');
    return DateTime(
      scheduledOn.year,
      scheduledOn.month,
      scheduledOn.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  List<Object?> get props => [
    id,
    specialty,
    kind,
    scheduledOn,
    time,
    place,
    remoteMethod,
    companionAccountId,
    companionName,
    status,
    updatedAt,
  ];
}

class AppointmentCompanion extends Equatable {
  const AppointmentCompanion({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class AppointmentDraft extends Equatable {
  const AppointmentDraft({
    required this.specialty,
    required this.kind,
    required this.scheduledOn,
    required this.time,
    required this.place,
    required this.remoteMethod,
    required this.companionAccountId,
  });

  final String specialty;
  final AppointmentKind kind;
  final DateTime scheduledOn;
  final String time;
  final String? place;
  final String? remoteMethod;
  final String companionAccountId;

  @override
  List<Object?> get props => [
    specialty,
    kind,
    scheduledOn,
    time,
    place,
    remoteMethod,
    companionAccountId,
  ];
}
