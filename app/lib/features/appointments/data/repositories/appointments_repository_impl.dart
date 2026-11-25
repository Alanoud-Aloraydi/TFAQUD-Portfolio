import 'dart:async';

import 'package:app/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:app/features/appointments/data/models/appointment_model.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository.dart';

/// The server owns the appointments. Each change is announced on
/// [changes] once the server accepts it.
class AppointmentsRepositoryImpl implements AppointmentsRepository {
  AppointmentsRepositoryImpl(this._remote);

  final AppointmentRemoteDataSource _remote;

  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  /// The circle whose appointments changed (calendar sync picks it up).
  @override
  Stream<String> get changes => _changes.stream;

  /// The circle's appointments; a row with an unknown status is left out.
  @override
  Future<List<CareAppointment>> appointments(String circleId) async {
    final values = await _remote.appointments(circleId);
    return values
        .map(
          (item) => AppointmentModel.tryFromJson(item as Map<String, dynamic>),
        )
        .nonNulls
        .toList();
  }

  /// The circle's members who can go, and whether the patient has a phone.
  @override
  Future<AppointmentCompanions> companions(String circleId) async =>
      companionsFromJson(await _remote.companions(circleId));

  /// Adds an appointment.
  @override
  Future<CareAppointment> create(String circleId, AppointmentDraft draft) =>
      _saved(circleId, _remote.create(circleId, draft));

  /// Changes a scheduled appointment.
  @override
  Future<CareAppointment> revise(
    String circleId,
    CareAppointment appointment,
    AppointmentDraft draft,
  ) => _saved(circleId, _remote.revise(circleId, appointment, draft));

  /// Marks an appointment attended or cancelled.
  @override
  Future<CareAppointment> setStatus(
    String circleId,
    CareAppointment appointment,
    AppointmentStatus status,
  ) => _saved(circleId, _remote.setStatus(circleId, appointment, status));

  /// Changes how an appointment went, from «السجل».
  @override
  Future<CareAppointment> changeOutcome(
    String circleId,
    CareAppointment appointment,
    AppointmentOutcome outcome,
  ) => _saved(circleId, _remote.changeOutcome(circleId, appointment, outcome));

  /// The appointment [answer] holds, once the server accepted the change.
  Future<CareAppointment> _saved(
    String circleId,
    Future<Map<String, dynamic>> answer,
  ) async {
    final CareAppointment result = _appointment(await answer);
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

/// Reads the answer of `GET …/appointments/companions`: the members who
/// may go, and whether the patient has an account (true from an older
/// server, which does not say).
AppointmentCompanions companionsFromJson(Map<String, dynamic> body) =>
    AppointmentCompanions(<AppointmentCompanion>[
      for (final Object? item in body['companions'] as List<dynamic>)
        AppointmentModel.companionFromJson(item! as Map<String, dynamic>),
    ], patientHasPhone: body['patient_has_account'] as bool? ?? true);
