import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/repositories/circles_repository_data.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A remote data source that answers from memory and records what it was
/// asked.
class _Remote extends Fake implements BaseCirclesRemoteDataSource {
  Object? error;
  final List<String> calls = <String>[];
  PatientUpdate? sentPatient;
  MedicalProfileDraft? sentProfile;
  ContactDraft? sentDraft;

  @override
  Future<MedicalFile> getMedicalFile(String circleId) async {
    calls.add('getMedicalFile:$circleId');
    if (error != null) throw error!;
    return _file;
  }

  @override
  Future<MedicalProfileDraft> updateMedicalProfile(
    String circleId,
    MedicalProfileDraft profile,
  ) async {
    calls.add('updateMedicalProfile:$circleId');
    sentProfile = profile;
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<void> updatePatient(String circleId, PatientUpdate update) async {
    calls.add('updatePatient:$circleId');
    sentPatient = update;
    if (error != null) throw error!;
  }

  @override
  Future<EmergencyContact> addContact(
    String circleId,
    ContactDraft draft,
  ) async {
    calls.add('addContact:$circleId');
    sentDraft = draft;
    if (error != null) throw error!;
    return _contact;
  }

  @override
  Future<EmergencyContact> updateContact(
    String circleId,
    String contactId,
    ContactDraft draft,
  ) async {
    calls.add('updateContact:$circleId:$contactId');
    sentDraft = draft;
    if (error != null) throw error!;
    return _contact;
  }

  @override
  Future<void> deleteContact(String circleId, String contactId) async {
    calls.add('deleteContact:$circleId:$contactId');
    if (error != null) throw error!;
  }

  @override
  Future<EmergencyCard> getEmergencyCard(String circleId) async {
    calls.add('getEmergencyCard:$circleId');
    if (error != null) throw error!;
    return _card;
  }
}

const EmergencyContact _contact = EmergencyContact(
  id: 'k-1',
  name: 'خالد',
  relation: 'son',
  phoneNumber: '+966512345678',
);

final MedicalFile _file = MedicalFile(
  patient: PatientBasics(
    firstName: 'نورة',
    lastName: 'العتيبي',
    birthDate: DateTime(1954, 6, 5),
    city: 'بريدة',
    hasAccount: false,
  ),
  profile: const MedicalProfileDraft(bloodType: 'O+'),
  contacts: const <EmergencyContact>[_contact],
);

final EmergencyCard _card = EmergencyCard(
  firstName: 'نورة',
  lastName: 'العتيبي',
  profile: const MedicalProfileDraft(bloodType: 'O+'),
  contacts: const <EmergencyContact>[_contact],
);

DioException _api(int status, String code) {
  final RequestOptions options = RequestOptions(
    path: '/circles/c-1/emergency-contacts',
  );
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: <String, dynamic>{
        'error': <String, dynamic>{'code': code, 'message': 'test'},
      },
    ),
  );
}

const ContactDraft _draft = ContactDraft(
  name: 'خالد',
  relation: 'son',
  phoneNumber: '+966512345678',
);

void main() {
  late _Remote remote;
  late CirclesRepositoryData repository;

  setUp(() {
    remote = _Remote();
    repository = CirclesRepositoryData(remote);
  });

  group('the entities', () {
    test('a contact shows its first letter and its number without +966', () {
      expect(_contact.initial, 'خ');
      expect(_contact.nationalNumber, '512345678');
    });

    test('a contact without a name has no letter', () {
      const EmergencyContact blank = EmergencyContact(
        id: 'k-2',
        name: '  ',
        relation: 'other',
        phoneNumber: '+966512345678',
      );
      expect(blank.initial, '');
    });

    test('a contact can be added until the patient has five', () {
      MedicalFile withContacts(int count) => _file.copyWith(
        contacts: <EmergencyContact>[
          for (int i = 0; i < count; i++)
            EmergencyContact(
              id: 'k-$i',
              name: 'اسم $i',
              relation: 'other',
              phoneNumber: '+96651234567$i',
            ),
        ],
      );
      expect(withContacts(4).canAddContact, isTrue);
      expect(withContacts(5).canAddContact, isFalse);
    });

    test('the full name is the first name and the last name', () {
      expect(_file.patient.fullName, 'نورة العتيبي');
      expect(_card.fullName, 'نورة العتيبي');
    });
  });

  group('CirclesRepositoryData, the medical file', () {
    test('reads the file', () async {
      final result = await repository.getMedicalFile('c-1');

      expect(result.tryGetSuccess(), _file);
      expect(remote.calls, <String>['getMedicalFile:c-1']);
    });

    test('a refusal of the server is read by the shared rules', () async {
      remote.error = _api(403, 'forbidden');

      final result = await repository.getMedicalFile('c-1');

      expect(result.tryGetError(), const ForbiddenFailure());
    });

    test('saves the health answers and gives them back', () async {
      const MedicalProfileDraft profile = MedicalProfileDraft(bloodType: 'A+');

      final result = await repository.updateMedicalProfile('c-1', profile);

      expect(result.tryGetSuccess(), profile);
      expect(remote.sentProfile, profile);
    });

    test('saves the basic data of the patient', () async {
      final PatientUpdate update = PatientUpdate(
        birthDate: DateTime(1954, 6, 5),
        city: 'بريدة',
      );

      final result = await repository.updatePatient('c-1', update);

      expect(result.isSuccess(), isTrue);
      expect(remote.sentPatient, update);
    });

    final Map<String, Failure> saveCodes = <String, Failure>{
      'profile_incomplete': const ProfileIncompleteFailure(),
      'invalid_birth_date': const InvalidBirthDateFailure(),
    };
    for (final MapEntry<String, Failure> entry in saveCodes.entries) {
      test('${entry.key} has its own failure when the data is saved', () async {
        remote.error = _api(422, entry.key);

        final result = await repository.updatePatient(
          'c-1',
          PatientUpdate(birthDate: DateTime(1954, 6, 5), city: 'بريدة'),
        );

        expect(result.tryGetError(), entry.value);
      });
    }
  });

  group('CirclesRepositoryData, the emergency contacts', () {
    test('adds a contact', () async {
      final result = await repository.addContact('c-1', _draft);

      expect(result.tryGetSuccess(), _contact);
      expect(remote.sentDraft, _draft);
    });

    test('changes a contact', () async {
      final result = await repository.updateContact('c-1', 'k-1', _draft);

      expect(result.tryGetSuccess(), _contact);
      expect(remote.calls, <String>['updateContact:c-1:k-1']);
    });

    test('removes a contact', () async {
      final result = await repository.deleteContact('c-1', 'k-1');

      expect(result.isSuccess(), isTrue);
      expect(remote.calls, <String>['deleteContact:c-1:k-1']);
    });

    test('too_many_contacts has its own failure', () async {
      remote.error = _api(422, 'too_many_contacts');

      final result = await repository.addContact('c-1', _draft);

      expect(result.tryGetError(), const TooManyContactsFailure());
    });

    test('duplicate_contact has its own failure, add and change', () async {
      remote.error = _api(422, 'duplicate_contact');

      expect(
        (await repository.addContact('c-1', _draft)).tryGetError(),
        const DuplicateContactFailure(),
      );
      expect(
        (await repository.updateContact('c-1', 'k-1', _draft)).tryGetError(),
        const DuplicateContactFailure(),
      );
    });

    test('a contact that is gone is "not found"', () async {
      remote.error = _api(404, 'not_found');

      final result = await repository.deleteContact('c-1', 'k-1');

      expect(result.tryGetError(), const NotFoundFailure());
    });
  });

  group('CirclesRepositoryData, the emergency card', () {
    test('reads the card', () async {
      final result = await repository.getEmergencyCard('c-1');

      expect(result.tryGetSuccess(), _card);
    });

    test('a person who is not in the circle is refused', () async {
      remote.error = _api(403, 'forbidden');

      final result = await repository.getEmergencyCard('c-1');

      expect(result.tryGetError(), const ForbiddenFailure());
    });
  });
}
