import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

/// What the patient sends after agreeing to a request (PROFILE-01C). The
/// patient's name comes from the account. A null birth date or city is read
/// from the account. Sending this creates the circle.
class CompleteCircleRequest extends Equatable {
  const CompleteCircleRequest({
    this.name,
    this.birthDate,
    this.city,
    this.medicalProfile,
  });

  /// The patient's own name for the circle («رعايتي», «صحتي»...). Only they
  /// see it; the others see «دائرة» and the patient's name. Null: the server
  /// names it «دائرتي».
  final String? name;

  final DateTime? birthDate;
  final String? city;

  /// Null when the patient answered no health question.
  final MedicalProfileDraft? medicalProfile;

  @override
  List<Object?> get props => [name, birthDate, city, medicalProfile];
}
