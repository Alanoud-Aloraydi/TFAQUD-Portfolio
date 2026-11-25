import 'package:app/features/circles/data/models/sent_circle_request_model.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';

export 'package:app/features/circles/data/models/previous_notifications_model.dart';
export 'package:app/features/circles/data/models/sent_circle_request_model.dart';

/// Reads the answer of GET /api/v1/circle-requests:
/// `{"sent": [...], "received": [...]}`.
class CircleRequestsModel {
  const CircleRequestsModel({required this.sent, required this.received});

  final List<SentCircleRequest> sent;
  final List<ReceivedCircleRequest> received;

  factory CircleRequestsModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> sent = (json['sent'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> received =
        (json['received'] as List<dynamic>?) ?? <dynamic>[];
    return CircleRequestsModel(
      sent: <SentCircleRequest>[
        for (final dynamic item in sent)
          SentCircleRequestModel.fromItem(item as Map<String, dynamic>)
              .toEntity(),
      ],
      received: <ReceivedCircleRequest>[
        for (final dynamic item in received)
          _received(item as Map<String, dynamic>),
      ],
    );
  }

  static ReceivedCircleRequest _received(Map<String, dynamic> item) {
    final Map<String, dynamic> by =
        (item['requested_by'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final String display = ((by['display_name'] as String?) ?? '').trim();
    final String first = (by['first_name'] as String?) ?? '';
    final String last = (by['last_name'] as String?) ?? '';
    return ReceivedCircleRequest(
      id: item['id'] as String,
      status: SentCircleRequestModel.parseStatus(item['status'] as String?),
      circleName: (item['circle_name'] as String?) ?? '',
      proposedAppMode: SentCircleRequestModel.parseMode(
        item['proposed_app_mode'] as String?,
      ),
      requesterName: display.isNotEmpty ? display : '$first $last'.trim(),
      requesterAvatarCode: by['avatar_code'] as String?,
      createdAt: SentCircleRequestModel.parseTime(item['created_at']),
    );
  }
}

/// The body of POST /api/v1/circle-requests (docs/api-contracts.md).
class NewCircleRequestModel {
  const NewCircleRequestModel(this._request);

  final NewCircleRequest _request;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'patient_phone_number': _request.patientPhoneNumber,
    'proposed_app_mode': _request.proposedAppMode.name,
  };
}

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
