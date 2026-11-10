import 'package:equatable/equatable.dart';

/// The signed-in account, as the circle pages and the account page show it:
/// the names, the phone number, and the circle the account already receives
/// care in.
class AccountSummary extends Equatable {
  const AccountSummary({
    required this.firstName,
    required this.lastName,
    this.displayName = '',
    this.phoneNumber = '',
    this.patientCircleId,
    this.birthDate,
    this.city,
    this.avatarCode,
  });

  final String firstName;
  final String lastName;

  /// The name other members of a circle see.
  final String displayName;

  /// The sign-in number with the country code, `+9665XXXXXXXX`.
  final String phoneNumber;

  /// The id of the circle this account is the patient of, or null. An account
  /// can be the patient of one circle only.
  final String? patientCircleId;

  /// The birth date and city that onboarding saved, or null for an account
  /// made before onboarding asked for them.
  final DateTime? birthDate;
  final String? city;
  final String? avatarCode;

  /// True when a circle for this account's own care needs only its name: the
  /// server reads the birth date and city from the account.
  bool get hasBasics => birthDate != null && city != null;

  /// The first name and the last name together, as the "Name" field shows it.
  String get fullName => '$firstName $lastName'.trim();

  /// True when the account already has a circle for its own care.
  bool get hasOwnCircle => patientCircleId != null;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    displayName,
    phoneNumber,
    patientCircleId,
    birthDate,
    city,
    avatarCode,
  ];
}
