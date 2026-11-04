import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/data/appointment_remote_data_source.dart';
import 'package:app/features/appointments/domain/appointment.dart';

/// Provides appointment data operations.
class AppointmentRepository {
  AppointmentRepository(this._remote);

  final AppointmentRemoteDataSource _remote;

  Future<List<CareAppointment>> appointments(String circleId) async {
    final values = await _remote.appointments(circleId);
    return values
        .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppointmentCompanion>> companions(String circleId) async {
    final values = await _remote.companions(circleId);
    return values
        .map(
          (item) =>
              AppointmentModel.companionFromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CareAppointment> create(
    String circleId,
    AppointmentDraft draft,
  ) async => _appointment(await _remote.create(circleId, draft));

  Future<CareAppointment> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) async => _appointment(await _remote.revise(circleId, appointment, draft));

  Future<CareAppointment> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) async =>
      _appointment(await _remote.setStatus(circleId, appointment, status));

  static CareAppointment _appointment(Map<String, dynamic> data) =>
      AppointmentModel.fromJson(data['appointment'] as Map<String, dynamic>);
}
