import 'package:equatable/equatable.dart';

/// The basic data of the patient that the edit page saves: PUT
/// /api/v1/circles/{id}/patient.
///
/// The server replaces the birth date, the city and the coordinates, and the
/// zone when one is sent. The names are sent for a patient without an
/// account only; the server refuses them for a patient who has an account,
/// because those names belong to the account.
class PatientUpdate extends Equatable {
  const PatientUpdate({
    required this.birthDate,
    required this.city,
    this.firstName,
    this.lastName,
    this.latitude,
    this.longitude,
    this.timeZone,
  });

  final DateTime birthDate;
  final String city;

  /// Null for a patient who has an account.
  final String? firstName;
  final String? lastName;

  /// Kept when the city did not change, and null otherwise: the coordinates of
  /// an old city would be wrong.
  final double? latitude;
  final double? longitude;

  /// The IANA zone where the patient lives; null keeps the saved one.
  final String? timeZone;

  @override
  List<Object?> get props => [
    birthDate,
    city,
    firstName,
    lastName,
    latitude,
    longitude,
    timeZone,
  ];
}
