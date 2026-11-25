import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:multiple_result/multiple_result.dart';

/// The medical file of a circle, and telling the open pages of that
/// circle when it was saved.
mixin MedicalFileUseCase on CirclesUseCaseScope {
  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId) =>
      repository.getMedicalFile(circleId);

  /// The medical files saved on one page, for the other pages of the same
  /// circle that are open under it (the medical file page and the circle
  /// tab), so they show the new answers at once instead of reading the file
  /// from the server again.
  final StreamController<(String, MedicalFile)> _savedFiles =
      StreamController<(String, MedicalFile)>.broadcast();

  /// Each medical file of [circleId] saved from now on, the newest last.
  Stream<MedicalFile> medicalFileSaves(String circleId) => _savedFiles.stream
      .where(((String, MedicalFile) saved) => saved.$1 == circleId)
      .map(((String, MedicalFile) saved) => saved.$2);

  /// Tells the open pages that [file] is now the saved medical file of
  /// [circleId]. Called after the server accepted the change.
  void medicalFileSaved(String circleId, MedicalFile file) =>
      _savedFiles.add((circleId, file));

  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) => repository.updateMedicalProfile(circleId, profile);

  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  ) => repository.updatePatient(circleId, update);

  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  ) => repository.addContact(circleId, draft);

  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) => repository.updateContact(circleId, contactId, draft);

  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  ) => repository.deleteContact(circleId, contactId);

  Future<Result<EmergencyCard, Failure>> getEmergencyCard(String circleId) =>
      repository.getEmergencyCard(circleId);
}
