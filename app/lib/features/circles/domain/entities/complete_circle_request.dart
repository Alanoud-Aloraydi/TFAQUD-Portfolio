import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// What the patient sends after agreeing to a request (PROFILE-01C). The name
/// comes from the account and the circle name from the request, so neither is
/// here. A null birth date or city is read from the account. Sending this
/// creates the circle.
class CompleteCircleRequest extends Equatable {
  const CompleteCircleRequest({
    this.birthDate,
    this.city,
    this.medicalProfile,
  });

  final DateTime? birthDate;
  final String? city;

  /// Null when the patient answered no health question.
  final MedicalProfileDraft? medicalProfile;

  @override
  List<Object?> get props => [birthDate, city, medicalProfile];
}
