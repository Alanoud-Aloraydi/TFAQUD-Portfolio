part of '../circles_repository_data.dart';

/// Reading the medical file and saving the patient's part of it.
mixin _MedicalFileCalls implements CirclesRepositoryDomain {
  BaseCirclesRemoteDataSource get _remote;

  @override
  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId) async {
    try {
      return Success(await _remote.getMedicalFile(circleId));
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) async {
    try {
      return Success(await _remote.updateMedicalProfile(circleId, profile));
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  ) async {
    try {
      await _remote.updatePatient(circleId, update);
      return const Success(null);
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }
}
