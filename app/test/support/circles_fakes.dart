import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// A circles repository that answers from memory and records what it was asked
/// to create.
class CirclesFakeRepository extends Fake implements CirclesRepositoryDomain {
  static const AccountSummary reem = AccountSummary(
    firstName: 'Reem',
    lastName: 'Alahmadi',
    displayName: 'Reem',
    phoneNumber: '+966501234567',
  );
  static const CareCircleSummary newCircle = CareCircleSummary(
    id: 'new-circle',
    name: 'My care',
  );

  static const SentCircleRequest waitingRequest = SentCircleRequest(
    id: 'request-1',
    patientPhoneNumber: '+966501234567',
    circleLabel: 'أمي',
    proposedAppMode: CircleAppMode.simplified,
    status: CircleRequestStatus.pending,
  );

  /// A request addressed to the signed-in person, waiting for the answer.
  static const ReceivedCircleRequest askedOfNoura = ReceivedCircleRequest(
    id: 'request-in-1',
    status: CircleRequestStatus.pending,
    circleLabel: 'أمي',
    circleName: 'أمي نورة',
    proposedAppMode: CircleAppMode.simplified,
    requesterName: 'سارة الحربي',
  );

  /// The same request after the person agreed and before the basic data.
  static const ReceivedCircleRequest agreedByNoura = ReceivedCircleRequest(
    id: 'request-in-1',
    status: CircleRequestStatus.accepted,
    circleLabel: 'أمي',
    circleName: 'أمي نورة',
    proposedAppMode: CircleAppMode.simplified,
    requesterName: 'سارة الحربي',
  );

  static const ReceivedInvitation invitedByKhaled = ReceivedInvitation(
    id: 'invitation-1',
    circleName: 'أمي نورة',
    invitedByName: 'خالد',
  );

  /// The people to call in the medical file of [nouraFile].
  static const EmergencyContact khaled = EmergencyContact(
    id: 'contact-1',
    name: 'خالد',
    relation: 'son',
    phoneNumber: '+966512345678',
  );
  static const EmergencyContact huda = EmergencyContact(
    id: 'contact-2',
    name: 'هدى',
    relation: 'daughter',
    phoneNumber: '+966598765432',
  );

  /// The medical file of a patient without an account: the blood type O+,
  /// diabetes, no allergies, and two contacts.
  static final MedicalFile nouraFile = MedicalFile(
    patient: PatientBasics(
      firstName: 'نورة',
      lastName: 'العتيبي',
      birthDate: DateTime(1954, 6, 5),
      city: 'بريدة',
      hasAccount: false,
      latitude: 26.33,
      longitude: 43.97,
    ),
    profile: const MedicalProfileDraft(
      bloodType: 'O+',
      conditions: ConditionsDraft.listed(codes: <String>['diabetes']),
      allergies: AllergiesDraft.none(),
    ),
    contacts: const <EmergencyContact>[khaled, huda],
  );

  /// The same file, for a patient who uses the app.
  static final MedicalFile nouraWithAccount = nouraFile.copyWith(
    patient: PatientBasics(
      firstName: 'نورة',
      lastName: 'العتيبي',
      birthDate: DateTime(1954, 6, 5),
      city: 'بريدة',
      hasAccount: true,
      latitude: 26.33,
      longitude: 43.97,
    ),
  );

  static final EmergencyCard nouraCard = EmergencyCard(
    firstName: 'نورة',
    lastName: 'العتيبي',
    profile: nouraFile.profile,
    contacts: const <EmergencyContact>[khaled, huda],
  );

  Result<AccountSummary, Failure> account = const Success(reem);
  Result<CareCircleSummary, Failure> created = const Success(newCircle);
  Result<CareCircleSummary, Failure> createdPatient = const Success(
    newCircle,
  );
  Result<SentCircleRequest, Failure> sent = const Success(waitingRequest);

  Result<CircleInbox, Failure> inbox = const Success(CircleInbox.empty());
  Result<CircleRequestStatus, Failure> replied = const Success(
    CircleRequestStatus.accepted,
  );
  Result<String?, Failure> invitationReplied = const Success<String?, Failure>(
    'circle-from-invitation',
  );
  Result<CareCircleSummary, Failure> completed = const Success(newCircle);
  Result<void, Failure> canceled = const Success(null);
  Result<void, Failure> deleted = const Success(null);

  // The medical file, the emergency contacts and the emergency card.
  Result<MedicalFile, Failure> medicalFile = Success(nouraFile);
  Result<EmergencyCard, Failure> emergencyCard = Success(nouraCard);
  Result<void, Failure> patientUpdated = const Success(null);
  Result<void, Failure> contactDeleted = const Success(null);

  /// When set, saving the health answers answers with it. Otherwise the
  /// answers are given back as sent, like the server does.
  Result<MedicalProfileDraft, Failure>? profileSaved;

  /// When set, adding or changing a contact answers with it. Otherwise the
  /// contact is given back as sent.
  Result<EmergencyContact, Failure>? contactSaved;

  /// When set, a create call waits for it, so a test can act in between.
  Future<Result<CareCircleSummary, Failure>>? pending;

  /// When set, adding or changing a contact waits for it.
  Future<Result<EmergencyContact, Failure>>? pendingContact;

  /// The answers of the next reads of the medical file, used one by one before
  /// [medicalFile] is used again.
  final List<Future<Result<MedicalFile, Failure>>> queuedFileReads =
      <Future<Result<MedicalFile, Failure>>>[];

  final List<NewSelfCircle> requests = <NewSelfCircle>[];
  final List<NewPatientCircle> patientCircles = <NewPatientCircle>[];
  final List<NewCircleRequest> sentRequests = <NewCircleRequest>[];
  int inboxReads = 0;

  /// The id and the answer (true = yes) of each reply, in order.
  final List<(String, bool)> requestAnswers = <(String, bool)>[];
  final List<(String, bool)> invitationAnswers = <(String, bool)>[];
  final List<String> completedIds = <String>[];
  final List<CompleteCircleRequest> completions = <CompleteCircleRequest>[];
  final List<String> canceledIds = <String>[];
  final List<AccountDeletion> deletions = <AccountDeletion>[];

  int medicalFileReads = 0;
  int emergencyCardReads = 0;

  /// The calls that save the medical file, in order: `patient`, `profile`,
  /// `add`, `change` and `delete`.
  final List<String> saveCalls = <String>[];
  final List<PatientUpdate> patientUpdates = <PatientUpdate>[];
  final List<MedicalProfileDraft> profileUpdates = <MedicalProfileDraft>[];
  final List<ContactDraft> addedContacts = <ContactDraft>[];

  /// The id and the new values of each contact change.
  final List<(String, ContactDraft)> changedContacts =
      <(String, ContactDraft)>[];
  final List<String> deletedContactIds = <String>[];

  void reset() {
    account = const Success(reem);
    created = const Success(newCircle);
    createdPatient = const Success(newCircle);
    sent = const Success(waitingRequest);
    inbox = const Success(CircleInbox.empty());
    replied = const Success(CircleRequestStatus.accepted);
    invitationReplied = const Success<String?, Failure>('circle-from-invitation');
    completed = const Success(newCircle);
    canceled = const Success(null);
    deleted = const Success(null);
    medicalFile = Success(nouraFile);
    emergencyCard = Success(nouraCard);
    patientUpdated = const Success(null);
    contactDeleted = const Success(null);
    profileSaved = null;
    contactSaved = null;
    pending = null;
    pendingContact = null;
    queuedFileReads.clear();
    requests.clear();
    patientCircles.clear();
    sentRequests.clear();
    inboxReads = 0;
    requestAnswers.clear();
    invitationAnswers.clear();
    completedIds.clear();
    completions.clear();
    canceledIds.clear();
    deletions.clear();
    medicalFileReads = 0;
    emergencyCardReads = 0;
    saveCalls.clear();
    patientUpdates.clear();
    profileUpdates.clear();
    addedContacts.clear();
    changedContacts.clear();
    deletedContactIds.clear();
  }

  @override
  Future<Result<AccountSummary, Failure>> getAccount() async => account;

  @override
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) async {
    requests.add(circle);
    return pending ?? created;
  }

  @override
  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  ) async {
    patientCircles.add(circle);
    return pending ?? createdPatient;
  }

  @override
  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  ) async {
    sentRequests.add(request);
    return sent;
  }

  @override
  Future<Result<CircleInbox, Failure>> getInbox() async {
    inboxReads++;
    return inbox;
  }

  @override
  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  }) async {
    requestAnswers.add((id, accept));
    return replied;
  }

  @override
  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  }) async {
    invitationAnswers.add((id, accept));
    return invitationReplied;
  }

  @override
  Future<Result<CareCircleSummary, Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  ) async {
    completedIds.add(id);
    completions.add(request);
    return pending ?? completed;
  }

  @override
  Future<Result<void, Failure>> cancelRequest(String id) async {
    canceledIds.add(id);
    return canceled;
  }

  @override
  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion) async {
    deletions.add(deletion);
    return deleted;
  }

  @override
  Future<Result<MedicalFile, Failure>> getMedicalFile(String circleId) {
    medicalFileReads++;
    if (queuedFileReads.isNotEmpty) return queuedFileReads.removeAt(0);
    return Future<Result<MedicalFile, Failure>>.value(medicalFile);
  }

  @override
  Future<Result<MedicalProfileDraft, Failure>> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) async {
    saveCalls.add('profile');
    profileUpdates.add(profile);
    return profileSaved ??
        Success<MedicalProfileDraft, Failure>(profile);
  }

  @override
  Future<Result<void, Failure>> updatePatient(
    String circleId,
    PatientUpdate update,
  ) async {
    saveCalls.add('patient');
    patientUpdates.add(update);
    return patientUpdated;
  }

  @override
  Future<Result<EmergencyContact, Failure>> addContact(
    String circleId,
    ContactDraft draft,
  ) async {
    saveCalls.add('add');
    addedContacts.add(draft);
    return pendingContact ??
        contactSaved ??
        Success<EmergencyContact, Failure>(
          EmergencyContact(
            id: 'new-contact',
            name: draft.name,
            relation: draft.relation,
            phoneNumber: draft.phoneNumber,
          ),
        );
  }

  @override
  Future<Result<EmergencyContact, Failure>> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) async {
    saveCalls.add('change');
    changedContacts.add((contactId, draft));
    return pendingContact ??
        contactSaved ??
        Success<EmergencyContact, Failure>(
          EmergencyContact(
            id: contactId,
            name: draft.name,
            relation: draft.relation,
            phoneNumber: draft.phoneNumber,
          ),
        );
  }

  @override
  Future<Result<void, Failure>> deleteContact(
    String circleId,
    String contactId,
  ) async {
    saveCalls.add('delete');
    deletedContactIds.add(contactId);
    return contactDeleted;
  }

  @override
  Future<Result<EmergencyCard, Failure>> getEmergencyCard(
    String circleId,
  ) async {
    emergencyCardReads++;
    return emergencyCard;
  }
}
