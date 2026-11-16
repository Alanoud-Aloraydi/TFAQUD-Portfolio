import 'package:app/features/circles/data/models/sent_circle_request_model.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';

/// Reads the answer of GET /api/v1/notifications/previous:
/// `{"previous": [...]}`, newest first. An item of a kind this app does not
/// know, or without its time, is left out.
abstract class PreviousNotificationsModel {
  PreviousNotificationsModel._();

  static const Map<String, PreviousKind> _kinds = <String, PreviousKind>{
    'invitation_received': PreviousKind.invitationReceived,
    'invitation_sent': PreviousKind.invitationSent,
    'request_received': PreviousKind.requestReceived,
    'request_sent': PreviousKind.requestSent,
  };

  static List<PreviousNotification> fromJson(Map<String, dynamic> json) {
    final List<dynamic> items =
        (json['previous'] as List<dynamic>?) ?? <dynamic>[];
    return <PreviousNotification>[
      for (final dynamic raw in items) ?_item(raw as Map<String, dynamic>),
    ];
  }

  static PreviousNotification? _item(Map<String, dynamic> item) {
    final PreviousKind? kind = _kinds[item['kind']];
    final DateTime? answeredAt = SentCircleRequestModel.parseTime(
      item['answered_at'],
    );
    if (kind == null || answeredAt == null) return null;
    return PreviousNotification(
      id: item['id'] as String,
      kind: kind,
      accepted: item['status'] != 'declined',
      answeredAt: answeredAt,
      circleName: item['circle_name'] as String?,
      otherName: item['other_name'] as String?,
      otherAvatarCode: item['other_avatar_code'] as String?,
      otherPhoneNumber: item['other_phone_number'] as String?,
    );
  }
}
