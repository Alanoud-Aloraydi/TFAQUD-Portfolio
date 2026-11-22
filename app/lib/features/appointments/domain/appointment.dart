export 'package:app/features/appointments/domain/appointment_companion.dart';
export 'package:app/features/appointments/domain/appointment_draft.dart';
export 'package:app/features/appointments/domain/appointment_kind.dart';
export 'package:app/features/appointments/domain/appointment_kind_group.dart';
export 'package:app/features/appointments/domain/appointment_status.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment_companion.dart';
import 'package:app/features/appointments/domain/appointment_kind.dart';
import 'package:app/features/appointments/domain/appointment_props.dart';
import 'package:app/features/appointments/domain/appointment_reminder_lead.dart';
import 'package:app/features/appointments/domain/appointment_status.dart';
import 'package:equatable/equatable.dart';

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
