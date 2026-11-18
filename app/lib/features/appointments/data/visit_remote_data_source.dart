import 'dart:typed_data';

import 'package:app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:app/core/network/appointment_endpoints.dart';

/// Sends visit requests to the API.
class VisitRemoteDataSource {
  VisitRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> get(String circleId, String id) async {
    final response = await _client.get(
      AppointmentEndpoints.appointmentVisit(circleId, id),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> save(
    String circleId,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      AppointmentEndpoints.appointmentVisit(circleId, id),
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Uint8List> audio(String circleId, String id) async {
    final response = await _client.dio.get<List<int>>(
      AppointmentEndpoints.appointmentVisitAudio(circleId, id),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Map<String, dynamic>> saveAudio(
    String circleId,
    String id,
    Uint8List bytes,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      AppointmentEndpoints.appointmentVisitAudio(circleId, id),
      data: Stream.value(bytes),
      options: Options(
        contentType: 'audio/mp4',
        headers: {Headers.contentLengthHeader: bytes.length},
      ),
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> removeAudio(String circleId, String id) async {
    final response = await _client.delete(
      AppointmentEndpoints.appointmentVisitAudio(circleId, id),
    );
    return response.data as Map<String, dynamic>;
  }
}
