import 'package:app/features/appointments/domain/appointment.dart';

/// What makes two [CareAppointment]s equal: every field, in the order the
/// class declares them.
List<Object?> careAppointmentProps(CareAppointment state) => <Object?>[
  state.id,
  state.specialty,
  state.kind,
  state.otherKind,
  state.scheduledOn,
  state.time,
  state.place,
  state.remoteMethod,
  state.companions,
  state.reminderLeadMinutes,
  state.status,
  state.updatedAt,
  state.createdByName,
  state.updatedByName,
  state.createdBy,
  state.updatedBy,
];
