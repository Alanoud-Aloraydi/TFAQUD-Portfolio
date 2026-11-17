import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment_reminder_lead.dart';
import 'package:equatable/equatable.dart';

/// What the visit is for; the form groups these by [AppointmentKindGroup].
enum AppointmentKind {
  followUp,
  newVisit,
  remote,
  emergency,
  test,
  imaging,
  eyeExam,
  hearingTest,
  surgery,
  physio,
  dialysis,
  therapySession,
  dressing,
  vaccine,
  checkup,
  dental,
  pharmacy,
  mental,
  speech,
  other;

  /// The wire name: «follow_up» for [followUp].
  String get code => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (Match m) => '_${m[0]!.toLowerCase()}',
  );

  /// The kind with this wire name; [other] for one this app does not know.
  static AppointmentKind fromCode(String code) => values.firstWhere(
    (AppointmentKind kind) => kind.code == code,
    orElse: () => other,
  );
}

/// The rows of the form's type choice; [AppointmentKind.other] stands alone.
enum AppointmentKindGroup {
  visit(<AppointmentKind>[
    AppointmentKind.followUp,
    AppointmentKind.newVisit,
    AppointmentKind.remote,
    AppointmentKind.emergency,
  ]),
  checks(<AppointmentKind>[
    AppointmentKind.test,
    AppointmentKind.imaging,
    AppointmentKind.eyeExam,
    AppointmentKind.hearingTest,
  ]),
  treatment(<AppointmentKind>[
    AppointmentKind.surgery,
    AppointmentKind.physio,
    AppointmentKind.dialysis,
    AppointmentKind.therapySession,
    AppointmentKind.dressing,
  ]),
  routine(<AppointmentKind>[
    AppointmentKind.vaccine,
    AppointmentKind.checkup,
    AppointmentKind.dental,
    AppointmentKind.pharmacy,
  ]),
  sessions(<AppointmentKind>[AppointmentKind.mental, AppointmentKind.speech]);

  const AppointmentKindGroup(this.kinds);

  final List<AppointmentKind> kinds;
}

enum AppointmentStatus { scheduled, completed, cancelled }

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
    reminderLeadMinutes,
    status,
    updatedAt,
    createdByName,
    updatedByName,
    createdBy,
    updatedBy,
  ];
}

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

  /// How long before the visit to remind, in minutes; one of
  /// [appointmentLeadChoices].
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
