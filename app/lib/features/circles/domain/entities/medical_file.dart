export 'package:app/features/circles/domain/entities/medical_gap.dart';
export 'package:app/features/circles/domain/entities/patient_basics.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_gap.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_basics.dart';
import 'package:equatable/equatable.dart';

/// The whole medical file page: the patient, the health answers and the
/// emergency contacts.
///
/// [profile] is a [MedicalProfileDraft] whose parts are null while the answer
/// is "unknown" (nobody has answered yet). "None" is a real answer and is not
/// null.
class MedicalFile extends Equatable {
  MedicalFile({
    required this.patient,
    required this.profile,
    required List<EmergencyContact> contacts,
  }) : contacts = List.unmodifiable(contacts);

  /// The server keeps at most this many contacts for a patient.
  static const int maxContacts = 5;

  final PatientBasics patient;
  final MedicalProfileDraft profile;
  final List<EmergencyContact> contacts;

  bool get canAddContact => contacts.length < maxContacts;

  /// The medical answers nobody has given yet: the blood type, the chronic
  /// conditions and the allergies. A circle is created without them, so the
  /// circle page and the file mark them with «!» until they are filled.
  /// "None" is an answer, so it does not count.
  List<MedicalGap> get gaps => <MedicalGap>[
    if (profile.bloodType == null) MedicalGap.bloodType,
    if (profile.conditions == null) MedicalGap.conditions,
    if (profile.allergies == null) MedicalGap.allergies,
  ];

  bool get needsFilling => gaps.isNotEmpty;

  MedicalFile copyWith({
    PatientBasics? patient,
    MedicalProfileDraft? profile,
    List<EmergencyContact>? contacts,
  }) {
    return MedicalFile(
      patient: patient ?? this.patient,
      profile: profile ?? this.profile,
      contacts: contacts ?? this.contacts,
    );
  }

  @override
  List<Object?> get props => [patient, profile, contacts];
}
