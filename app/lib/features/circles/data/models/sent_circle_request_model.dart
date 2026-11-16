import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';

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
        proposedAppMode: parseMode(request['proposed_app_mode'] as String?),
        status: parseStatus(request['status'] as String?),
        createdAt: parseTime(request['created_at']),
        respondedAt: parseTime(request['responded_at']),
      ),
    );
  }

  SentCircleRequest toEntity() => _entity;

  static CircleAppMode parseMode(String? value) =>
      value == 'detailed' ? CircleAppMode.detailed : CircleAppMode.simplified;

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
