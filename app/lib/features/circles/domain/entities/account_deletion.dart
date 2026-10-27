import 'package:equatable/equatable.dart';

/// What happens to the circle the account receives care in when the account is
/// deleted.
enum PatientChoice {
  /// The circle is deleted with the account.
  delete,

  /// The circle stays. The patient's names are copied into it as plain text,
  /// and the other managers go on.
  keep,
}

/// The choices the person made before deleting the account. The server asks
/// for each one only when it matters.
class AccountDeletion extends Equatable {
  const AccountDeletion({
    this.patientChoice,
    this.deleteLastManagedCircles = false,
  });

  final PatientChoice? patientChoice;

  /// Also delete the circles where this account is the only manager.
  final bool deleteLastManagedCircles;

  AccountDeletion copyWith({
    PatientChoice? patientChoice,
    bool? deleteLastManagedCircles,
  }) => AccountDeletion(
    patientChoice: patientChoice ?? this.patientChoice,
    deleteLastManagedCircles:
        deleteLastManagedCircles ?? this.deleteLastManagedCircles,
  );

  @override
  List<Object?> get props => [patientChoice, deleteLastManagedCircles];
}
