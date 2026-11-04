import 'package:app/features/appointments/domain/appointment.dart';

/// Maps appointment data between the API and app.
class AppointmentModel {
  const AppointmentModel._();

  static AppointmentCompanion companionFromJson(Map<String, dynamic> json) =>
      AppointmentCompanion(
        id: json['account_id'] as String,
        name: json['name'] as String,
        avatarCode: json['avatar_code'] as String?,
      );

  static CareAppointment fromJson(Map<String, dynamic> json) => CareAppointment(
    id: json['id'] as String,
    specialty: json['specialty'] as String,
    kind: AppointmentKind.values.byName(
      json['kind'] == 'follow_up' ? 'followUp' : json['kind'] as String,
    ),
    otherKind: json['other_kind'] as String?,
    scheduledOn: DateTime.parse(json['scheduled_on'] as String),
    time: json['time_of_day'] as String,
    place: json['place'] as String?,
    remoteMethod: json['remote_method'] as String?,
    companionAccountId: json['companion_account_id'] as String,
    companionName: json['companion_name'] as String,
    companionAvatarCode: json['companion_avatar_code'] as String?,
    status: AppointmentStatus.values.byName(json['status'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  static Map<String, dynamic> toJson(
    AppointmentDraft draft, {
    DateTime? expectedUpdatedAt,
  }) => {
    'specialty': draft.specialty,
    'kind': draft.kind == AppointmentKind.followUp
        ? 'follow_up'
        : draft.kind.name,
    'other_kind': draft.otherKind,
    'scheduled_on':
        '${draft.scheduledOn.year.toString().padLeft(4, '0')}-'
        '${draft.scheduledOn.month.toString().padLeft(2, '0')}-'
        '${draft.scheduledOn.day.toString().padLeft(2, '0')}',
    'time_of_day': draft.time,
    'place': draft.place,
    'remote_method': draft.remoteMethod,
    'companion_account_id': draft.companionAccountId,
    if (expectedUpdatedAt != null)
      'expected_updated_at': expectedUpdatedAt.toUtc().toIso8601String(),
  };
}
