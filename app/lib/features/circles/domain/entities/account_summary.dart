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
  ];
}
