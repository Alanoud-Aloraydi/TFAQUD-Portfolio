import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/domain/appointment.dart';

class AppointmentRemoteDataSource {
  AppointmentRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<dynamic>> appointments(String circleId) async {
    final response = await _client.get(ApiEndpoints.appointments(circleId));
    return (response.data as Map<String, dynamic>)['appointments']
        as List<dynamic>;
  }

  Future<List<dynamic>> companions(String circleId) async {
    final response = await _client.get(
      ApiEndpoints.appointmentCompanions(circleId),
    );
    return (response.data as Map<String, dynamic>)['companions']
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(
    String circleId,
    AppointmentDraft draft,
  ) async {
    final response = await _client.post(
      ApiEndpoints.appointments(circleId),
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
      ApiEndpoints.appointment(circleId, appointment.id),
      data: AppointmentModel.toJson(
        draft,
        expectedUpdatedAt: appointment.updatedAt,
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) async {
    final response = await _client.post(
      ApiEndpoints.appointmentStatus(circleId, appointment.id),
      data: {
        'status': status.name,
        'expected_updated_at': appointment.updatedAt.toUtc().toIso8601String(),
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
