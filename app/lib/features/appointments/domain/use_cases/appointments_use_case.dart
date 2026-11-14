import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository_domain.dart';

/// The appointment reads and writes the application is allowed to make.
class AppointmentsUseCase {
  AppointmentsUseCase(this._repository);

  final AppointmentsRepositoryDomain _repository;

  /// The circle whose appointments changed, so the lists showing them read
  /// again and the reminders are set afresh.
  Stream<String> get changes => _repository.changes;

  Future<List<CareAppointment>> appointments(String circleId) =>
      _repository.appointments(circleId);

  Future<List<AppointmentCompanion>> companions(String circleId) =>
      _repository.companions(circleId);

  Future<CareAppointment> create(String circleId, AppointmentDraft draft) =>
      _repository.create(circleId, draft);

  Future<CareAppointment> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) => _repository.revise(circleId, appointment, draft);

  Future<CareAppointment> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) => _repository.setStatus(circleId, appointment, status);
}
