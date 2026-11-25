import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:multiple_result/multiple_result.dart';

/// The medical file of a circle, its emergency contacts, and the
/// card read from them.
abstract class MedicalFileRepository {
  /// The medical file of a circle: GET /api/v1/circles/{id}/medical-profile.
  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId);

  /// Saves the health answers: PATCH /api/v1/circles/{id}/medical-profile. A
  /// part with no answer is cleared back to "unknown". Returns what the server
  /// saved.
  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  );

  /// Saves the birth date, the city and, for a patient without an account, the
  /// names: PUT /api/v1/circles/{id}/patient.
  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  );

  /// Adds an emergency contact: POST /api/v1/circles/{id}/emergency-contacts.
  /// [TooManyContactsFailure] and [DuplicateContactFailure] are the refusals
  /// that have their own text.
  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  );

  /// Changes an emergency contact: PUT
  /// /api/v1/circles/{id}/emergency-contacts/{contactId}.
  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  );

  /// Removes an emergency contact: DELETE
  /// /api/v1/circles/{id}/emergency-contacts/{contactId}.
  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  );

  /// The read-only emergency card: GET /api/v1/circles/{id}/emergency-card.
  Future<Result<EmergencyCard, Failure>> getEmergencyCard(String circleId);
}
