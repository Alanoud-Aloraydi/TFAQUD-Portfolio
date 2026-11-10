import 'package:equatable/equatable.dart';

/// What the user typed to create a circle for a patient who does not use the
/// app. The user manages the circle. The names of the patient are typed here,
/// because there is no account to read them from. Nobody names the circle:
/// the server names it «دائرة» and the patient's first name.
class NewPatientCircle extends Equatable {
  const NewPatientCircle({
    required this.patientFirstName,
    required this.patientLastName,
    required this.birthDate,
    required this.city,
  });

  final String patientFirstName;
  final String patientLastName;
  final DateTime birthDate;
  final String city;

  @override
  List<Object?> get props => [
    patientFirstName,
    patientLastName,
    birthDate,
    city,
  ];
}
