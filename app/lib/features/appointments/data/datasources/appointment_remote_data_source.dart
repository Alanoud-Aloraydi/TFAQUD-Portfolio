import 'package:app/core/network/appointment_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';

/// Sends appointment requests to the API.
class AppointmentRemoteDataSource {
  AppointmentRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<dynamic>> appointments(String circleId) async {
    final response = await _client.get(
      AppointmentEndpoints.appointments(circleId),
    );
    return (response.data as Map<String, dynamic>)['appointments']
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> companions(String circleId) async {
    final response = await _client.get(
      AppointmentEndpoints.appointmentCompanions(circleId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(
    String circleId,
    AppointmentDraft draft,
  ) async {
    final response = await _client.post(
      AppointmentEndpoints.appointments(circleId),
      data: AppointmentModel.toJson(draft),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) async {
    final response = await _client.put(
      AppointmentEndpoints.appointment(circleId, appointment.id),
      data: AppointmentModel.toJson(
        draft,
        expectedUpdatedAt: appointment.updatedAt,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changeOutcome(
    String circleId,
    CareAppointment appointment,
    AppointmentOutcome outcome,
  ) async {
    final response = await _client.post(
      AppointmentEndpoints.appointmentOutcome(circleId, appointment.id),
      data: {
        'status': outcome.name,
        'expected_updated_at': appointment.updatedAt.toUtc().toIso8601String(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) async {
    final response = await _client.post(
      AppointmentEndpoints.appointmentStatus(circleId, appointment.id),
      data: {
        'status': status.name,
        'expected_updated_at': appointment.updatedAt.toUtc().toIso8601String(),
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
