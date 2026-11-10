import 'package:app/core/utils/api_date.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';

/// The body of POST /api/v1/circles/self (docs/api-contracts.md).
/// [timeZone] is the patient's IANA zone.
class NewSelfCircleModel {
  const NewSelfCircleModel(this._circle, [this._timeZone]);

  final NewSelfCircle _circle;
  final String? _timeZone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': _circle.name,
    'birth_date': apiDate(_circle.birthDate),
    'city': _circle.city,
    'time_zone': ?_timeZone,
  };
}
