import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment_reminder_lead.dart';
import 'package:app/features/appointments/domain/entities/appointment_series.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/appointments/domain/entities/appointment_kind_group.dart';
export 'package:app/features/appointments/domain/entities/appointment_series.dart';

/// One planned visit: what for, when, where, and who goes along.
class CareAppointment extends Equatable {
  const CareAppointment({
    required this.id,
    this.specialty,
    required this.kind,
    required this.otherKind,
    required this.scheduledOn,
    required this.time,
    required this.place,
    required this.remoteMethod,
    required this.companions,
    this.reminderLeadMinutes = defaultAppointmentLead,
    required this.status,
    required this.updatedAt,
    this.seriesId,
    this.createdByName,
    this.updatedByName,
    this.createdBy,
    this.updatedBy,
    this.markedMissed = false,
    this.visitFilled = false,
  });

  final String id;

  /// The clinic or doctor as typed; null when not given.
  final String? specialty;
  final AppointmentKind kind;
  final String? otherKind;
  final DateTime scheduledOn;
  final String time;
  final String? place;
  final String? remoteMethod;
  final List<AppointmentCompanion> companions;

  /// The booking this visit was saved with, when several dates were chosen
  /// at once; null for a visit on its own. It ties them for «الزيارة 2 من
  /// 6» and nothing else: an edit here never reaches the others.
  final String? seriesId;

  /// The accounts going with the patient.
  Iterable<String> get companionIds =>
      companions.map((AppointmentCompanion companion) => companion.id);

  /// How long before its time this visit's own reminder comes, in
  /// minutes; the day-before reminder is set besides it and is not
  /// chosen. [defaultAppointmentLead] from a server that does not say.
  final int reminderLeadMinutes;

  /// That lead as a duration, for the reminder plan.
  Duration get reminderLead => Duration(minutes: reminderLeadMinutes);
  final AppointmentStatus status;
  final DateTime updatedAt;

  /// «فائت» was chosen for it from «السجل»: still open, missed at once.
  final bool markedMissed;

  /// Its «ورقة الزيارة» has something in it, so it stays «حضرت».
  final bool visitFilled;

  /// Who added or last changed it, for tracking; null when unavailable.
  final String? createdByName;
  final String? updatedByName;

  /// The same people with their accounts and avatars, for their pictures.
  final AppointmentCompanion? createdBy;
  final AppointmentCompanion? updatedBy;

  /// The visit's wall time where the patient lives, on the scale of
  /// [PatientClock.now].
  DateTime get scheduledAt => wallClockAt(scheduledOn, time);

  @override
  List<Object?> get props => careAppointmentProps(this);
}

enum AppointmentStatus { scheduled, completed, cancelled }

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
