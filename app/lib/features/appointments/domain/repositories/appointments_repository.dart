import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';

/// The appointments of a circle, wherever they are kept.
abstract class AppointmentsRepository {
  /// The circle whose appointments changed, each time a change is accepted.
  Stream<String> get changes;

  /// The circle's appointments; one with an unknown status is left out.
  Future<List<CareAppointment>> appointments(String circleId);

  /// The circle's members who can go with the patient, and whether the
  /// patient has a phone.
  Future<AppointmentCompanions> companions(String circleId);

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

  /// Changes how an appointment went, from «السجل».
  Future<CareAppointment> changeOutcome(
    String circleId,
    CareAppointment appointment,
    AppointmentOutcome outcome,
  );
}
