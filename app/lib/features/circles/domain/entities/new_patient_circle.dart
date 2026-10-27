import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// What the user typed to create a circle for a patient who does not use the
/// app. The user manages the circle. The names of the patient are typed here,
/// because there is no account to read them from.
class NewPatientCircle extends Equatable {
  const NewPatientCircle({
    required this.name,
    required this.patientFirstName,
    required this.patientLastName,
    required this.birthDate,
    required this.city,
    this.medicalProfile,
  });

  /// The name the circle shows in the list of circles: the chosen label and the
  /// first name of the patient, for example "أمي نورة".
  final String name;
  final String patientFirstName;
  final String patientLastName;
  final DateTime birthDate;
  final String city;

  /// Null when the user answered no health question.
  final MedicalProfileDraft? medicalProfile;

  @override
  List<Object?> get props => [
    name,
    patientFirstName,
    patientLastName,
    birthDate,
    city,
    medicalProfile,
  ];
}
