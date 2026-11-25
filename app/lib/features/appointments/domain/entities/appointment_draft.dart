import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_reminder_lead.dart';
import 'package:equatable/equatable.dart';

/// Holds editable appointment values before saving.
class AppointmentDraft extends Equatable {
  const AppointmentDraft({
    this.specialty,
    required this.kind,
    required this.otherKind,
    required this.scheduledOn,
    required this.time,
    required this.place,
    required this.remoteMethod,
    required this.companionAccountIds,
    this.reminderLeadMinutes = defaultAppointmentLead,
    this.alsoOn = const <DateTime>[],
  });

  /// The clinic or doctor as typed; null when not given.
  final String? specialty;
  final AppointmentKind kind;
  final String? otherKind;
  final DateTime scheduledOn;
  final String time;
  final String? place;
  final String? remoteMethod;
  final List<String> companionAccountIds;

  /// How long before the visit to remind, in minutes, from
  /// [minAppointmentLead] to [maxAppointmentLead].
  final int reminderLeadMinutes;

  /// The other dates booked at the same time, each saved as its own visit
  /// with these same answers. Empty for a visit on its own.
  final List<DateTime> alsoOn;

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
    reminderLeadMinutes,
    alsoOn,
  ];
}

/// What makes two [CareAppointment]s equal: every field, in the order the
/// class declares them.
List<Object?> careAppointmentProps(CareAppointment state) => <Object?>[
  state.id,
  state.specialty,
  state.kind,
  state.otherKind,
  state.scheduledOn,
  state.time,
  state.place,
  state.remoteMethod,
  state.companions,
  state.reminderLeadMinutes,
  state.status,
  state.updatedAt,
  state.createdByName,
  state.updatedByName,
  state.createdBy,
  state.updatedBy,
  state.markedMissed,
  state.visitFilled,
];

/// Identifies a circle member accompanying an appointment, or who added or
/// changed one.
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
