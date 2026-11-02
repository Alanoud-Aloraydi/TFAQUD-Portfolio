import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// What the user chose to create a circle for their own care. The patient's
/// names are not here: the API takes them from the account, and also the
/// birth date and city when they are null (onboarding saved them).
class NewSelfCircle extends Equatable {
  const NewSelfCircle({
    required this.name,
    this.birthDate,
    this.city,
    this.medicalProfile,
  });

  /// The name the circle shows in the list of circles.
  final String name;
  final DateTime? birthDate;
  final String? city;

  /// Null when the user answered no health question.
  final MedicalProfileDraft? medicalProfile;

  @override
  List<Object?> get props => [name, birthDate, city, medicalProfile];
}
