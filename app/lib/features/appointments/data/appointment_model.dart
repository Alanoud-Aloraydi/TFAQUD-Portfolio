import 'package:app/core/utils/api_date.dart';
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

  /// The appointment in [json], or null when its status is one this app does
  /// not know: one such row must not hide the whole list. An unknown kind
  /// reads as [AppointmentKind.other].
  static CareAppointment? tryFromJson(Map<String, dynamic> json) {
    final status = AppointmentStatus.values
        .where((value) => value.name == json['status'])
        .firstOrNull;
    return status == null ? null : _fromJson(json, status);
  }

  static CareAppointment _fromJson(
    Map<String, dynamic> json,
    AppointmentStatus status,
  ) => CareAppointment(
    id: json['id'] as String,
    specialty: json['specialty'] as String?,
    kind: AppointmentKind.fromCode(json['kind'] as String),
    otherKind: json['other_text'] as String?,
    scheduledOn: DateTime.parse(json['scheduled_on'] as String),
    time: json['time_of_day'] as String,
    place: json['place'] as String?,
    remoteMethod: json['remote_method'] as String?,
    companions: (json['companions'] as List<dynamic>)
        .map((item) => companionFromJson(item as Map<String, dynamic>))
        .toList(),
    status: status,
    updatedAt: DateTime.parse(json['updated_at'] as String),
    createdByName:
        (json['created_by'] as Map<String, dynamic>?)?['name'] as String?,
    updatedByName:
        (json['updated_by'] as Map<String, dynamic>?)?['name'] as String?,
    createdBy: _person(json['created_by']),
    updatedBy: _person(json['updated_by']),
  );

  /// Who did something, as `recorded_by` shapes it; null for nobody.
  static AppointmentCompanion? _person(Object? value) =>
      value is Map<String, dynamic> && value['account_id'] is String
      ? AppointmentCompanion(
          id: value['account_id'] as String,
          name: value['name'] as String? ?? '',
          avatarCode: value['avatar_code'] as String?,
        )
      : null;

  static Map<String, dynamic> toJson(
    AppointmentDraft draft, {
    DateTime? expectedUpdatedAt,
  }) => {
    'specialty': draft.specialty,
    'kind': draft.kind.code,
    'other_text': draft.otherKind,
    'scheduled_on': apiDate(draft.scheduledOn),
    'time_of_day': draft.time,
    'place': draft.place,
    'remote_method': draft.remoteMethod,
    'companion_account_ids': draft.companionAccountIds,
    if (expectedUpdatedAt != null)
      'expected_updated_at': expectedUpdatedAt.toUtc().toIso8601String(),
  };
}
