import 'package:app/core/utils/patient_clock.dart';
import 'package:equatable/equatable.dart';

/// A circle whose schedule reminds the person on this phone: its id, the
/// name the reminder shows («أمي نورة»), and who that person is in it.
/// Shared by the dose, measurement, and appointment reminder schedulers,
/// and by calendar sync.
///
/// Every member hears of a dose and of a measurement. An appointment
/// reminds only those who go: the patient, and the members going with
/// them ([remindsOfAppointment]).
class ReminderCircle extends Equatable {
  const ReminderCircle({
    required this.id,
    required this.name,
    required this.viewerId,
    required this.viewerIsPatient,
    required this.timeZone,
  });

  final String id;
  final String name;

  /// The account of the person on this phone; null where only the
  /// reminder's words are needed.
  final String? viewerId;

  /// Whether the person on this phone is the circle's patient.
  final bool viewerIsPatient;

  /// The IANA zone where the circle's patient lives: its doses, readings
  /// and visits happen at the patient's wall clock there ([clock]).
  final String timeZone;

  /// The patient's clock, for the moments of the reminders.
  PatientClock get clock => PatientClock(timeZone);

  /// Whether an appointment going with [companionIds] (accounts) reminds
  /// the person on this phone: the patient always, anyone else only when
  /// they go with them.
  bool remindsOfAppointment(Iterable<String> companionIds) =>
      viewerIsPatient || (viewerId != null && companionIds.contains(viewerId));

  @override
  List<Object?> get props => [id, name, viewerId, viewerIsPatient, timeZone];
}
