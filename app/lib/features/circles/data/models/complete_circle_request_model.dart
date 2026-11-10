import 'package:app/core/utils/api_date.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';

/// The body of POST /api/v1/circle-requests/{id}/complete
/// (docs/api-contracts.md): the patient's own name for the circle, the birth
/// date, the city and the patient's IANA zone ([timeZone]).
class CompleteCircleRequestModel {
  const CompleteCircleRequestModel(this._request, [this._timeZone]);

  final CompleteCircleRequest _request;
  final String? _timeZone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': _request.name,
    'birth_date': apiDate(_request.birthDate),
    'city': _request.city,
    'time_zone': ?_timeZone,
  };
}
