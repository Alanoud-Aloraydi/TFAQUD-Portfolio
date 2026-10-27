import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// What the patient types after agreeing to a request (PROFILE-01C, PROFILE-02
/// and PROFILE-03). The name comes from the account and the circle name from
/// the request, so neither is here. Sending this creates the circle.
class CompleteCircleRequest extends Equatable {
  const CompleteCircleRequest({
    required this.birthDate,
    required this.city,
    this.medicalProfile,
  });

  final DateTime birthDate;
  final String city;

  /// Null when the patient answered no health question.
  final MedicalProfileDraft? medicalProfile;

  @override
  List<Object?> get props => [birthDate, city, medicalProfile];
}
