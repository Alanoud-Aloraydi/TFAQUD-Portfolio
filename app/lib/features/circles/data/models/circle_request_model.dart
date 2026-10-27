import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';

/// The body of POST /api/v1/circle-requests (docs/api-contracts.md).
class NewCircleRequestModel {
  const NewCircleRequestModel(this._request);

  final NewCircleRequest _request;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'patient_phone_number': _request.patientPhoneNumber,
    'circle_label': _request.circleLabel,
    'proposed_app_mode': _request.proposedAppMode.name,
  };
}

/// Reads one request as the sender sees it. It is the answer of
/// POST /api/v1/circle-requests and of the respond call, `{"request": {...}}`,
/// and an item of `sent` in GET /api/v1/circle-requests.
class SentCircleRequestModel {
  const SentCircleRequestModel(this._entity);

  final SentCircleRequest _entity;

  factory SentCircleRequestModel.fromJson(Map<String, dynamic> json) {
    return SentCircleRequestModel.fromItem(
      json['request'] as Map<String, dynamic>,
    );
  }

  /// An item of the request, without the `request` wrapper.
  factory SentCircleRequestModel.fromItem(Map<String, dynamic> request) {
    return SentCircleRequestModel(
      SentCircleRequest(
        id: request['id'] as String,
        patientPhoneNumber: request['patient_phone_number'] as String,
        circleLabel: request['circle_label'] as String,
        proposedAppMode: parseMode(request['proposed_app_mode'] as String?),
        status: parseStatus(request['status'] as String?),
        createdAt: parseTime(request['created_at']),
      ),
    );
  }

  SentCircleRequest toEntity() => _entity;

  static CircleAppMode parseMode(String? value) => value == 'detailed'
      ? CircleAppMode.detailed
      : CircleAppMode.simplified;

  static CircleRequestStatus parseStatus(String? value) => switch (value) {
    'pending' => CircleRequestStatus.pending,
    'accepted' => CircleRequestStatus.accepted,
    'declined' => CircleRequestStatus.declined,
    _ => CircleRequestStatus.other,
  };

  /// The server writes times in UTC, ISO 8601. Anything else is "unknown".
  static DateTime? parseTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

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
    final String label = item['circle_label'] as String;
    final Map<String, dynamic> by =
        (item['requested_by'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final String display = ((by['display_name'] as String?) ?? '').trim();
    final String first = (by['first_name'] as String?) ?? '';
    final String last = (by['last_name'] as String?) ?? '';
    return ReceivedCircleRequest(
      id: item['id'] as String,
      status: SentCircleRequestModel.parseStatus(item['status'] as String?),
      circleLabel: label,
      circleName: (item['circle_name'] as String?) ?? label,
      proposedAppMode: SentCircleRequestModel.parseMode(
        item['proposed_app_mode'] as String?,
      ),
      requesterName: display.isNotEmpty ? display : '$first $last'.trim(),
      createdAt: SentCircleRequestModel.parseTime(item['created_at']),
    );
  }
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
    final Map<String, dynamic>? by = item['invited_by'] as Map<String, dynamic>?;
    return ReceivedInvitation(
      id: item['id'] as String,
      circleName: item['circle_name'] as String,
      invitedByName: by?['display_name'] as String?,
      createdAt: SentCircleRequestModel.parseTime(item['created_at']),
    );
  }
}
