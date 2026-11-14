import 'package:app/features/appointments/domain/appointment.dart';

/// The appointments of a circle, wherever they are kept.
abstract class AppointmentsRepositoryDomain {
  /// The circle whose appointments changed, each time a change is accepted.
  Stream<String> get changes;

  /// The circle's appointments; one with an unknown status is left out.
  Future<List<CareAppointment>> appointments(String circleId);

  /// The circle's members who can go with the patient.
  Future<List<AppointmentCompanion>> companions(String circleId);

  Future<CareAppointment> create(String circleId, AppointmentDraft draft);

  Future<CareAppointment> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  );

  /// Marks an appointment attended or cancelled.
  Future<CareAppointment> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  );
}
