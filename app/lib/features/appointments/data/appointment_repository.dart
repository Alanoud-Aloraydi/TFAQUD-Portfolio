import 'dart:async';

import 'package:app/features/appointments/data/appointment_model.dart';
import 'package:app/features/appointments/data/appointment_remote_data_source.dart';
import 'package:app/features/appointments/domain/appointment.dart';

/// Provides appointment data operations.
class AppointmentRepository {
  AppointmentRepository(this._remote);

  final AppointmentRemoteDataSource _remote;

  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  /// The circle whose appointments changed, each time the server accepts a
  /// change (so calendar sync can pick it up right away).
  Stream<String> get changes => _changes.stream;

  /// The circle's appointments; a row with an unknown status is left out.
  Future<List<CareAppointment>> appointments(String circleId) async {
    final values = await _remote.appointments(circleId);
    return values
        .map(
          (item) => AppointmentModel.tryFromJson(item as Map<String, dynamic>),
        )
        .nonNulls
        .toList();
  }

  /// The circle's members who can go with the patient.
  Future<List<AppointmentCompanion>> companions(String circleId) async {
    final values = await _remote.companions(circleId);
    return values
        .map(
          (item) =>
              AppointmentModel.companionFromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Adds an appointment; announces the change on [changes].
  Future<CareAppointment> create(
    String circleId,
    AppointmentDraft draft,
  ) async {
    final result = _appointment(await _remote.create(circleId, draft));
    _changes.add(circleId);
    return result;
  }

  /// Changes a scheduled appointment; announces the change on [changes].
  Future<CareAppointment> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) async {
    final result = _appointment(
      await _remote.revise(circleId, appointment, draft),
    );
    _changes.add(circleId);
    return result;
  }

  /// Marks an appointment attended or cancelled; announces the change on
  /// [changes].
  Future<CareAppointment> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) async {
    final result = _appointment(
      await _remote.setStatus(circleId, appointment, status),
    );
    _changes.add(circleId);
    return result;
  }

  /// The appointment the server answered with after a change.
  static CareAppointment _appointment(Map<String, dynamic> data) {
    final json = data['appointment'] as Map<String, dynamic>;
    return AppointmentModel.tryFromJson(json) ??
        (throw const FormatException('Unknown appointment status'));
  }
}
