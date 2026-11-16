import 'package:app/core/utils/time_zones.dart';
import 'package:equatable/equatable.dart';

/// The basic data of the patient on the medical file page: GET
/// /api/v1/circles/{id}/medical-profile, part `patient`.
class PatientBasics extends Equatable {
  const PatientBasics({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.city,
    required this.hasAccount,
    this.latitude,
    this.longitude,
    this.timeZone = defaultPatientZone,
  });

  /// While the patient has an account the names are the account's names, and
  /// only the patient can change them (on the account page).
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String city;

  /// True when the patient uses the app. A patient without an account has the
  /// names typed by the managers, so the managers can edit them.
  final bool hasAccount;

  final double? latitude;
  final double? longitude;

  /// The IANA zone where the patient lives; every time of the circle is
  /// wall clock there.
  final String timeZone;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    birthDate,
    city,
    hasAccount,
    latitude,
    longitude,
    timeZone,
  ];
}
