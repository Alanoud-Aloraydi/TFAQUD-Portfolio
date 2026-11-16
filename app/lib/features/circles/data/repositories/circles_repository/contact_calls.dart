part of '../circles_repository_data.dart';

/// The emergency contacts and the emergency card.
mixin _ContactCalls implements CirclesRepositoryDomain {
  BaseCirclesRemoteDataSource get _remote;

  @override
  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  ) async {
    try {
      return Success(await _remote.addContact(circleId, draft));
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) async {
    try {
      return Success(await _remote.updateContact(circleId, contactId, draft));
    } catch (error) {
      return Error(_medicalFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  ) async {
    try {
      await _remote.deleteContact(circleId, contactId);
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<EmergencyCard, Failure>> getEmergencyCard(
    String circleId,
  ) async {
    try {
      return Success(await _remote.getEmergencyCard(circleId));
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
