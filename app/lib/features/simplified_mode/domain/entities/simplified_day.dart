import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:equatable/equatable.dart';

/// Everything the simplified mode shows for the patient's circle, as read
/// from the server. Statuses are not kept here: they depend on the time,
/// so they are worked out when shown (TodaySchedule).
class SimplifiedDay extends Equatable {
  SimplifiedDay({
    required this.circleId,
    required this.circleName,
    required this.accountId,
    required this.isPatient,
    required this.displayName,
    required List<DoseOccurrence> doses,
    required List<MeasurementOccurrence> measurements,
    required List<CareAppointment> appointments,
    required List<CircleMember> family,
    required Map<String, String> reasons,
    this.avatarCode,
    this.prayers,
  }) : doses = List<DoseOccurrence>.unmodifiable(doses),
       measurements = List<MeasurementOccurrence>.unmodifiable(measurements),
       appointments = List<CareAppointment>.unmodifiable(appointments),
       family = List<CircleMember>.unmodifiable(family),
       reasons = Map<String, String>.unmodifiable(reasons);

  final String circleId;

  /// The name reminders show for the circle.
  final String circleName;

  /// The signed-in account, and whether it is the circle's patient: who an
  /// appointment reminder is for.
  final String accountId;
  final bool isPatient;
  final String? displayName;
  final String? avatarCode;

  /// Today's and tomorrow's doses.
  final List<DoseOccurrence> doses;

  /// Today's measurement tasks.
  final List<MeasurementOccurrence> measurements;

  /// Every appointment of the circle.
  final List<CareAppointment> appointments;

  /// The other members of the circle who can be called.
  final List<CircleMember> family;

  /// Each medicine's reason for use («للسكر»), by plan id.
  final Map<String, String> reasons;

  /// Today's prayer times; null when they could not be read.
  final PrayerDay? prayers;

  @override
  List<Object?> get props => [
    circleId,
    circleName,
    accountId,
    isPatient,
    displayName,
    avatarCode,
    doses,
    measurements,
    appointments,
    family,
    reasons,
    prayers,
  ];
}
