import 'package:app/features/circles/domain/entities/new_circle_request.dart';

/// The body of POST /api/v1/circle-requests (docs/api-contracts.md).
class NewCircleRequestModel {
  const NewCircleRequestModel(this._request);

  final NewCircleRequest _request;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'patient_phone_number': _request.patientPhoneNumber,
    'proposed_app_mode': _request.proposedAppMode.name,
  };
}
