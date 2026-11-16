import 'package:app/features/circles/data/models/sent_circle_request_model.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';

/// Reads the answer of GET /api/v1/invitations: `{"invitations": [...]}`.
abstract class ReceivedInvitationsModel {
  ReceivedInvitationsModel._();

  static List<ReceivedInvitation> fromJson(Map<String, dynamic> json) {
    final List<dynamic> items =
        (json['invitations'] as List<dynamic>?) ?? <dynamic>[];
    return <ReceivedInvitation>[
      for (final dynamic raw in items) _invitation(raw as Map<String, dynamic>),
    ];
  }

  static ReceivedInvitation _invitation(Map<String, dynamic> item) {
    final Map<String, dynamic>? by =
        item['invited_by'] as Map<String, dynamic>?;
    return ReceivedInvitation(
      id: item['id'] as String,
      circleName: item['circle_name'] as String,
      invitedByName: by?['display_name'] as String?,
      invitedByAvatarCode: by?['avatar_code'] as String?,
      createdAt: SentCircleRequestModel.parseTime(item['created_at']),
    );
  }
}
