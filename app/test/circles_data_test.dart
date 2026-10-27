import 'package:app/core/di/configure_dependencies.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/models/account_model.dart';
import 'package:app/features/circles/data/models/circle_model.dart';
import 'package:app/features/circles/data/models/circle_request_model.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/data/models/new_patient_circle_model.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/data/repositories/circles_repository_data.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/request_age.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _Remote extends Fake implements BaseCirclesRemoteDataSource {
  Object? error;
  Map<String, dynamic>? sentBody;
  Map<String, dynamic>? sentPatientBody;
  Map<String, dynamic>? sentRequestBody;

  CircleRequestsModel requests = const CircleRequestsModel(
    sent: <SentCircleRequest>[],
    received: <ReceivedCircleRequest>[],
  );
  List<ReceivedInvitation> invitations = const <ReceivedInvitation>[];
  bool? answeredAccept;
  String? completedId;
  Map<String, dynamic>? completedBody;
  String? canceledId;
  AccountDeletion? sentDeletion;

  @override
  Future<AccountModel> getAccount() async {
    if (error != null) throw error!;
    return AccountModel.fromJson(<String, dynamic>{
      'account': <String, dynamic>{
        'id': 'abc',
        'first_name': 'Reem',
        'last_name': 'Alahmadi',
        'display_name': 'Reem',
      },
    });
  }

  @override
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body) async {
    sentBody = body.toJson();
    if (error != null) throw error!;
    return CircleModel.fromJson(<String, dynamic>{
      'circle': <String, dynamic>{
        'id': '71771639-aaba-41e3-9418-5cb3179894ce',
        'name': 'My care',
        'role': 'manager',
      },
    });
  }

  @override
  Future<CircleModel> createPatientCircle(NewPatientCircleModel body) async {
    sentPatientBody = body.toJson();
    if (error != null) throw error!;
    return CircleModel.fromJson(<String, dynamic>{
      'circle': <String, dynamic>{
        'id': '0f0d6d3c-3b0e-4d5a-9a53-7d4c5c0b2f10',
        'name': 'أمي نورة',
        'role': 'manager',
      },
    });
  }

  @override
  Future<SentCircleRequestModel> sendCircleRequest(
    NewCircleRequestModel body,
  ) async {
    sentRequestBody = body.toJson();
    if (error != null) throw error!;
    return SentCircleRequestModel.fromJson(_requestAnswer());
  }

  @override
  Future<CircleRequestsModel> getCircleRequests() async {
    if (error != null) throw error!;
    return requests;
  }

  @override
  Future<List<ReceivedInvitation>> getInvitations() async {
    if (error != null) throw error!;
    return invitations;
  }

  @override
  Future<SentCircleRequestModel> respondToRequest(
    String id, {
    required bool accept,
  }) async {
    answeredAccept = accept;
    if (error != null) throw error!;
    return SentCircleRequestModel.fromJson(
      _requestAnswer(status: accept ? 'accepted' : 'declined'),
    );
  }

  @override
  Future<String?> respondToInvitation(String id, {required bool accept}) async {
    answeredAccept = accept;
    if (error != null) throw error!;
    return accept ? 'circle-from-invitation' : null;
  }

  @override
  Future<CircleModel> completeRequest(
    String id,
    CompleteCircleRequestModel body,
  ) async {
    completedId = id;
    completedBody = body.toJson();
    if (error != null) throw error!;
    return CircleModel.fromJson(<String, dynamic>{
      'circle': <String, dynamic>{'id': 'circle-9', 'name': 'أمي نورة'},
    });
  }

  @override
  Future<void> cancelRequest(String id) async {
    canceledId = id;
    if (error != null) throw error!;
  }

  @override
  Future<void> deleteAccount(AccountDeletion deletion) async {
    sentDeletion = deletion;
    if (error != null) throw error!;
  }
}

Map<String, dynamic> _requestAnswer({
  String status = 'pending',
  String mode = 'simplified',
}) => <String, dynamic>{
  'request': <String, dynamic>{
    'id': '7c054a73-e522-4d1d-ae65-8fac8cf01e85',
    'patient_phone_number': '+966501234567',
    'circle_label': 'أمي',
    'proposed_app_mode': mode,
    'status': status,
    'created_at': '2026-10-26T08:03:19.816997+00:00',
    'responded_at': null,
    'care_circle_id': null,
  },
};

DioException _api(int status, String code) {
  final RequestOptions options = RequestOptions(path: '/circles/self');
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

NewSelfCircle _circle({MedicalProfileDraft? medical}) => NewSelfCircle(
  name: 'My care',
  birthDate: DateTime(1964, 3, 12),
  city: 'الرياض',
  medicalProfile: medical,
);

NewPatientCircle _patientCircle({MedicalProfileDraft? medical}) =>
    NewPatientCircle(
      name: 'أمي نورة',
      patientFirstName: 'نورة',
      patientLastName: 'العتيبي',
      birthDate: DateTime(1954, 6, 5),
      city: 'بريدة',
      medicalProfile: medical,
    );

const NewCircleRequest _request = NewCircleRequest(
  patientPhoneNumber: '+966501234567',
  circleLabel: 'أمي',
  proposedAppMode: CircleAppMode.simplified,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NewSelfCircleModel', () {
    test('writes the date as YYYY-MM-DD with two digits for month and day', () {
      expect(NewSelfCircleModel.isoDate(DateTime(1964, 3, 5)), '1964-03-05');
      expect(NewSelfCircleModel.isoDate(DateTime(2001, 11, 30)), '2001-11-30');
    });

    test('has no medical profile when the user answered nothing', () {
      final Map<String, dynamic> json = NewSelfCircleModel(_circle()).toJson();
      expect(json, <String, dynamic>{
        'name': 'My care',
        'birth_date': '1964-03-12',
        'city': 'الرياض',
      });
    });

    test('has no medical profile for a profile with no answer in it', () {
      final Map<String, dynamic> json = NewSelfCircleModel(
        _circle(medical: const MedicalProfileDraft()),
      ).toJson();
      expect(json.containsKey('medical_profile'), isFalse);
    });

    test('sends only the parts that were answered', () {
      final Map<String, dynamic> json = NewSelfCircleModel(
        _circle(medical: const MedicalProfileDraft(bloodType: 'O+')),
      ).toJson();
      expect(json['medical_profile'], <String, dynamic>{'blood_type': 'O+'});
    });

    test('writes conditions and allergies as the API codes them', () {
      final Map<String, dynamic> json = NewSelfCircleModel(
        _circle(
          medical: const MedicalProfileDraft(
            bloodType: 'AB-',
            conditions: ConditionsDraft.listed(
              codes: <String>['diabetes', 'other'],
              other: 'Gout',
            ),
            allergies: AllergiesDraft.listed(
              medication: <String>['penicillin'],
              food: <String>['milk', 'other'],
              otherFood: 'Kiwi',
            ),
          ),
        ),
      ).toJson();
      expect(json['medical_profile'], <String, dynamic>{
        'blood_type': 'AB-',
        'conditions': <String, dynamic>{
          'status': 'listed',
          'codes': <String>['diabetes', 'other'],
          'other': 'Gout',
        },
        'allergies': <String, dynamic>{
          'status': 'listed',
          'medication': <String>['penicillin'],
          'other_medication': null,
          'food': <String>['milk', 'other'],
          'other_food': 'Kiwi',
        },
      });
    });

    test('writes "none" answers with empty lists', () {
      final Map<String, dynamic> json = NewSelfCircleModel(
        _circle(
          medical: const MedicalProfileDraft(
            conditions: ConditionsDraft.none(),
            allergies: AllergiesDraft.none(),
          ),
        ),
      ).toJson();
      expect(json['medical_profile'], <String, dynamic>{
        'conditions': <String, dynamic>{
          'status': 'none',
          'codes': <String>[],
          'other': null,
        },
        'allergies': <String, dynamic>{
          'status': 'none',
          'medication': <String>[],
          'other_medication': null,
          'food': <String>[],
          'other_food': null,
        },
      });
    });
  });

  group('NewPatientCircleModel', () {
    test('has the names of the patient and no medical profile when empty', () {
      expect(NewPatientCircleModel(_patientCircle()).toJson(), <String, dynamic>{
        'name': 'أمي نورة',
        'patient_first_name': 'نورة',
        'patient_last_name': 'العتيبي',
        'birth_date': '1954-06-05',
        'city': 'بريدة',
      });
    });

    test('sends the medical profile as the self circle does', () {
      final Map<String, dynamic> json = NewPatientCircleModel(
        _patientCircle(medical: const MedicalProfileDraft(bloodType: 'O+')),
      ).toJson();
      expect(json['medical_profile'], <String, dynamic>{'blood_type': 'O+'});
    });
  });

  group('circle request models', () {
    test('the request body has the number, the label and the mode', () {
      expect(NewCircleRequestModel(_request).toJson(), <String, dynamic>{
        'patient_phone_number': '+966501234567',
        'circle_label': 'أمي',
        'proposed_app_mode': 'simplified',
      });
    });

    test('the detailed mode is written as the API names it', () {
      const NewCircleRequest detailed = NewCircleRequest(
        patientPhoneNumber: '+966501234567',
        circleLabel: 'أمي',
        proposedAppMode: CircleAppMode.detailed,
      );
      expect(
        NewCircleRequestModel(detailed).toJson()['proposed_app_mode'],
        'detailed',
      );
    });

    test('the answer keeps what the waiting page shows', () {
      final SentCircleRequest sent = SentCircleRequestModel.fromJson(
        _requestAnswer(mode: 'detailed'),
      ).toEntity();
      expect(sent.id, '7c054a73-e522-4d1d-ae65-8fac8cf01e85');
      expect(sent.patientPhoneNumber, '+966501234567');
      expect(sent.circleLabel, 'أمي');
      expect(sent.proposedAppMode, CircleAppMode.detailed);
      expect(sent.status, CircleRequestStatus.pending);
    });

    test('an accepted request keeps its status; an unknown one is "other"', () {
      expect(
        SentCircleRequestModel.fromJson(
          _requestAnswer(status: 'accepted'),
        ).toEntity().status,
        CircleRequestStatus.accepted,
      );
      expect(
        SentCircleRequestModel.fromJson(
          _requestAnswer(status: 'completed'),
        ).toEntity().status,
        CircleRequestStatus.other,
      );
    });
  });

  group('requests the signed-in person received', () {
    // The shape of GET /api/v1/circle-requests in docs/api-contracts.md.
    final Map<String, dynamic> listed = <String, dynamic>{
      'sent': <dynamic>[_requestAnswer(status: 'declined')['request']],
      'received': <dynamic>[
        <String, dynamic>{
          'id': 'in-1',
          'status': 'pending',
          'circle_label': 'أمي',
          'circle_name': 'أمي نورة',
          'proposed_app_mode': 'detailed',
          'requested_by': <String, dynamic>{
            'display_name': 'سارة',
            'first_name': 'سارة',
            'last_name': 'الحربي',
          },
          'created_at': '2026-10-26T08:03:19.816997+00:00',
        },
      ],
    };

    test('keeps the sent requests and the received ones apart', () {
      final CircleRequestsModel model = CircleRequestsModel.fromJson(listed);
      expect(model.sent.single.status, CircleRequestStatus.declined);
      final ReceivedCircleRequest received = model.received.single;
      expect(received.id, 'in-1');
      expect(received.status, CircleRequestStatus.pending);
      expect(received.circleLabel, 'أمي');
      expect(received.circleName, 'أمي نورة');
      expect(received.proposedAppMode, CircleAppMode.detailed);
      expect(received.requesterName, 'سارة');
      expect(received.createdAt, DateTime.utc(2026, 10, 26, 8, 3, 19, 816, 997));
      expect(received.isAccepted, isFalse);
    });

    test('an accepted request knows it was accepted', () {
      final Map<String, dynamic> accepted = <String, dynamic>{
        'sent': <dynamic>[],
        'received': <dynamic>[
          <String, dynamic>{
            ...((listed['received'] as List<dynamic>).single
                as Map<String, dynamic>),
            'status': 'accepted',
          },
        ],
      };
      expect(
        CircleRequestsModel.fromJson(accepted).received.single.isAccepted,
        isTrue,
      );
    });

    test('the sender is the full name when there is no display name', () {
      final Map<String, dynamic> item = Map<String, dynamic>.of(
        (listed['received'] as List<dynamic>).single as Map<String, dynamic>,
      )..['requested_by'] = <String, dynamic>{
          'display_name': null,
          'first_name': 'سارة',
          'last_name': 'الحربي',
        };
      final CircleRequestsModel model = CircleRequestsModel.fromJson(
        <String, dynamic>{'sent': <dynamic>[], 'received': <dynamic>[item]},
      );
      expect(model.received.single.requesterName, 'سارة الحربي');
    });

    test('the circle name is the label when the server sent no name', () {
      final Map<String, dynamic> item = Map<String, dynamic>.of(
        (listed['received'] as List<dynamic>).single as Map<String, dynamic>,
      )..remove('circle_name');
      final CircleRequestsModel model = CircleRequestsModel.fromJson(
        <String, dynamic>{'received': <dynamic>[item]},
      );
      expect(model.received.single.circleName, 'أمي');
      // A list that is left out is an empty list, not a crash.
      expect(model.sent, isEmpty);
    });

    test('the invitations keep the circle and who invited', () {
      final List<ReceivedInvitation> invitations =
          ReceivedInvitationsModel.fromJson(<String, dynamic>{
            'invitations': <dynamic>[
              <String, dynamic>{
                'id': 'inv-1',
                'circle_name': 'أمي نورة',
                'invited_by': <String, dynamic>{'display_name': 'خالد'},
                'created_at': '2026-10-26T08:03:19+00:00',
                'last_sent_at': '2026-10-26T08:03:19+00:00',
              },
              <String, dynamic>{'id': 'inv-2', 'circle_name': 'أبي'},
            ],
          });
      expect(invitations, hasLength(2));
      expect(invitations.first.id, 'inv-1');
      expect(invitations.first.circleName, 'أمي نورة');
      expect(invitations.first.invitedByName, 'خالد');
      expect(invitations.first.createdAt, DateTime.utc(2026, 10, 26, 8, 3, 19));
      // An invitation with no sender name and no time is still shown.
      expect(invitations.last.invitedByName, isNull);
      expect(invitations.last.createdAt, isNull);
    });

    test('no invitations is an empty list', () {
      expect(
        ReceivedInvitationsModel.fromJson(<String, dynamic>{}),
        isEmpty,
      );
    });

    test('the inbox counts what waits for an answer', () {
      final CircleRequestsModel model = CircleRequestsModel.fromJson(listed);
      final CircleInbox inbox = CircleInbox(
        sent: model.sent,
        received: model.received,
        invitations: const <ReceivedInvitation>[
          ReceivedInvitation(id: 'inv-1', circleName: 'أمي نورة'),
        ],
      );
      // A declined request that this person sent needs no answer.
      expect(inbox.needsReply, 2);
      expect(const CircleInbox.empty().needsReply, 0);
    });
  });

  group('CompleteCircleRequestModel', () {
    test('has the birth date and the city only when nothing else was typed', () {
      final CompleteCircleRequest request = CompleteCircleRequest(
        birthDate: DateTime(1954, 6, 5),
        city: 'بريدة',
      );
      expect(CompleteCircleRequestModel(request).toJson(), <String, dynamic>{
        'birth_date': '1954-06-05',
        'city': 'بريدة',
      });
    });

    test('adds the medical profile when something was answered', () {
      final CompleteCircleRequest request = CompleteCircleRequest(
        birthDate: DateTime(1954, 6, 5),
        city: 'بريدة',
        medicalProfile: const MedicalProfileDraft(bloodType: 'O+'),
      );
      expect(
        CompleteCircleRequestModel(request).toJson()['medical_profile'],
        <String, dynamic>{'blood_type': 'O+'},
      );
    });

    test('leaves an empty medical profile out', () {
      final CompleteCircleRequest request = CompleteCircleRequest(
        birthDate: DateTime(1954, 6, 5),
        city: 'بريدة',
        medicalProfile: const MedicalProfileDraft(),
      );
      expect(
        CompleteCircleRequestModel(request).toJson().containsKey(
          'medical_profile',
        ),
        isFalse,
      );
    });
  });

  group('RequestAge', () {
    final DateTime now = DateTime.utc(2026, 10, 26, 12);

    test('counts whole days', () {
      expect(RequestAge.days(DateTime.utc(2026, 10, 26, 9), now), 0);
      expect(RequestAge.days(DateTime.utc(2026, 10, 25, 11), now), 1);
      expect(RequestAge.days(DateTime.utc(2026, 10, 24, 12), now), 2);
      expect(RequestAge.days(DateTime.utc(2026, 10, 1, 12), now), 25);
    });

    test('is never below zero when the phone clock is behind', () {
      expect(RequestAge.days(DateTime.utc(2026, 10, 27), now), 0);
    });

    test('is unknown when the server sent no time', () {
      expect(RequestAge.days(null, now), isNull);
    });
  });

  group('response models', () {
    test('the account keeps the first and the last name', () {
      final account = AccountModel.fromJson(<String, dynamic>{
        'account': <String, dynamic>{
          'id': 'abc',
          'first_name': 'Reem',
          'last_name': 'Alahmadi',
        },
      }).toEntity();
      expect(account.fullName, 'Reem Alahmadi');
      expect(account.patientCircleId, isNull);
      expect(account.hasOwnCircle, isFalse);
    });

    test('the account keeps the display name and the phone number', () {
      final account = AccountModel.fromJson(<String, dynamic>{
        'account': <String, dynamic>{
          'id': 'abc',
          'first_name': 'Reem',
          'last_name': 'Alahmadi',
          'display_name': 'Ree',
          'phone_number': '+966501234567',
        },
      }).toEntity();
      expect(account.displayName, 'Ree');
      expect(account.phoneNumber, '+966501234567');
    });

    test('an account with no display name or number has empty ones', () {
      final account = AccountModel.fromJson(<String, dynamic>{
        'account': <String, dynamic>{
          'id': 'abc',
          'first_name': 'Reem',
          'last_name': 'Alahmadi',
          'display_name': null,
        },
      }).toEntity();
      expect(account.displayName, '');
      expect(account.phoneNumber, '');
    });

    test('the account keeps the circle of its own care', () {
      final account = AccountModel.fromJson(<String, dynamic>{
        'account': <String, dynamic>{
          'id': 'abc',
          'first_name': 'Reem',
          'last_name': 'Alahmadi',
          'patient_circle_id': '71771639-aaba-41e3-9418-5cb3179894ce',
        },
      }).toEntity();
      expect(account.patientCircleId, '71771639-aaba-41e3-9418-5cb3179894ce');
      expect(account.hasOwnCircle, isTrue);
    });

    test('an account without names has an empty name, not a crash', () {
      final account = AccountModel.fromJson(<String, dynamic>{
        'account': <String, dynamic>{
          'id': 'abc',
          'first_name': null,
          'last_name': null,
        },
      }).toEntity();
      expect(account.fullName, '');
    });

    test('the circle keeps its id and name', () {
      final circle = CircleModel.fromJson(<String, dynamic>{
        'circle': <String, dynamic>{'id': 'c-1', 'name': 'My care'},
      }).toEntity();
      expect(circle.id, 'c-1');
      expect(circle.name, 'My care');
    });
  });

  group('CirclesRepositoryData', () {
    late _Remote remote;
    late CirclesRepositoryData repository;

    setUp(() {
      remote = _Remote();
      repository = CirclesRepositoryData(remote);
    });

    test('returns the new circle', () async {
      final result = await repository.createSelfCircle(_circle());
      result.when(
        (circle) {
          expect(circle.id, '71771639-aaba-41e3-9418-5cb3179894ce');
          expect(circle.name, 'My care');
        },
        (failure) => fail('Expected a circle, got $failure'),
      );
      expect(remote.sentBody!['birth_date'], '1964-03-12');
    });

    final Map<String, Failure> codes = <String, Failure>{
      'already_has_circle': const AlreadyHasCircleFailure(),
      'profile_incomplete': const ProfileIncompleteFailure(),
      'invalid_birth_date': const InvalidBirthDateFailure(),
    };
    for (final MapEntry<String, Failure> entry in codes.entries) {
      test('${entry.key} has its own failure', () async {
        remote.error = _api(422, entry.key);
        final result = await repository.createSelfCircle(_circle());
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, entry.value),
        );
      });
    }

    test('mode_conflict has its own failure', () async {
      remote.error = _api(422, 'mode_conflict');
      final result = await repository.createSelfCircle(_circle());
      result.when(
        (_) => fail('Expected a failure'),
        (failure) => expect(failure, const ModeConflictFailure()),
      );
    });

    test('a circle for a patient without the app is created', () async {
      final result = await repository.createPatientCircle(_patientCircle());
      result.when(
        (circle) {
          expect(circle.id, '0f0d6d3c-3b0e-4d5a-9a53-7d4c5c0b2f10');
          expect(circle.name, 'أمي نورة');
        },
        (failure) => fail('Expected a circle, got $failure'),
      );
      expect(remote.sentPatientBody!['patient_first_name'], 'نورة');
    });

    test('a refused patient circle has the same failures as a self circle',
        () async {
      remote.error = _api(422, 'mode_conflict');
      final result = await repository.createPatientCircle(_patientCircle());
      result.when(
        (_) => fail('Expected a failure'),
        (failure) => expect(failure, const ModeConflictFailure()),
      );
    });

    test('a request is sent and its answer is kept', () async {
      final result = await repository.sendCircleRequest(_request);
      result.when(
        (sent) => expect(sent.status, CircleRequestStatus.pending),
        (failure) => fail('Expected a request, got $failure'),
      );
      expect(remote.sentRequestBody!['patient_phone_number'], '+966501234567');
    });

    final Map<String, Failure> requestCodes = <String, Failure>{
      // For a request this code is about the patient, not the signed-in account.
      'already_has_circle': const PatientHasCircleFailure(),
      'self_request': const SelfRequestFailure(),
      'profile_incomplete': const ProfileIncompleteFailure(),
      'mode_conflict': const ModeConflictFailure(),
    };
    for (final MapEntry<String, Failure> entry in requestCodes.entries) {
      test('a request refused with ${entry.key} has its own failure',
          () async {
        remote.error = _api(422, entry.key);
        final result = await repository.sendCircleRequest(_request);
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, entry.value),
        );
      });
    }

    group('the inbox', () {
      test('puts the sent, the received and the invitations together',
          () async {
        remote.requests = CircleRequestsModel.fromJson(<String, dynamic>{
          'sent': <dynamic>[_requestAnswer()['request']],
          'received': <dynamic>[
            <String, dynamic>{
              'id': 'in-1',
              'status': 'pending',
              'circle_label': 'أمي',
              'circle_name': 'أمي نورة',
              'proposed_app_mode': 'simplified',
              'requested_by': <String, dynamic>{'display_name': 'سارة'},
            },
          ],
        });
        remote.invitations = const <ReceivedInvitation>[
          ReceivedInvitation(id: 'inv-1', circleName: 'أبي'),
        ];
        final result = await repository.getInbox();
        result.when(
          (CircleInbox inbox) {
            expect(inbox.sent, hasLength(1));
            expect(inbox.received.single.id, 'in-1');
            expect(inbox.invitations.single.id, 'inv-1');
            expect(inbox.needsReply, 2);
          },
          (failure) => fail('Expected an inbox, got $failure'),
        );
      });

      test('is a failure when either list cannot be read', () async {
        remote.error = DioException(
          requestOptions: RequestOptions(path: '/circle-requests'),
          type: DioExceptionType.connectionError,
        );
        final result = await repository.getInbox();
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const NetworkFailure()),
        );
      });
    });

    group('answering a request', () {
      test('agreeing gives back the status the server saved', () async {
        final result = await repository.respondToRequest('in-1', accept: true);
        expect(remote.answeredAccept, isTrue);
        result.when(
          (status) => expect(status, CircleRequestStatus.accepted),
          (failure) => fail('Expected a status, got $failure'),
        );
      });

      test('declining gives back "declined"', () async {
        final result = await repository.respondToRequest('in-1', accept: false);
        expect(remote.answeredAccept, isFalse);
        result.when(
          (status) => expect(status, CircleRequestStatus.declined),
          (failure) => fail('Expected a status, got $failure'),
        );
      });
    });

    group('answering an invitation', () {
      test('accepting gives back the circle that was joined', () async {
        final result = await repository.respondToInvitation(
          'inv-1',
          accept: true,
        );
        result.when(
          (circleId) => expect(circleId, 'circle-from-invitation'),
          (failure) => fail('Expected a circle id, got $failure'),
        );
      });

      test('declining gives back no circle', () async {
        final result = await repository.respondToInvitation(
          'inv-1',
          accept: false,
        );
        result.when(
          (circleId) => expect(circleId, isNull),
          (failure) => fail('Expected a result, got $failure'),
        );
      });
    });

    group('refused answers', () {
      // Every code that means "this request or invitation can no longer be
      // used" shows the same text.
      for (final String code in <String>[
        'request_not_pending',
        'request_not_cancelable',
        'invitation_not_pending',
        'already_manager',
        'consent_required',
      ]) {
        test('$code is "no longer available"', () async {
          remote.error = _api(422, code);
          final result = await repository.respondToRequest(
            'in-1',
            accept: true,
          );
          result.when(
            (_) => fail('Expected a failure'),
            (failure) => expect(failure, const RequestUnavailableFailure()),
          );
        });
      }

      final Map<String, Failure> replyCodes = <String, Failure>{
        // Here the code is about the signed-in person, not the patient.
        'already_has_circle': const AlreadyHasCircleFailure(),
        'accepted_request_exists': const AcceptedRequestExistsFailure(),
        'mode_conflict': const ReplyModeConflictFailure(),
        'profile_incomplete': const ProfileIncompleteFailure(),
        'invalid_birth_date': const InvalidBirthDateFailure(),
      };
      for (final MapEntry<String, Failure> entry in replyCodes.entries) {
        test('${entry.key} has its own failure', () async {
          remote.error = _api(422, entry.key);
          final result = await repository.respondToRequest(
            'in-1',
            accept: true,
          );
          result.when(
            (_) => fail('Expected a failure'),
            (failure) => expect(failure, entry.value),
          );
        });
      }

      test('the same codes are read for an invitation', () async {
        remote.error = _api(422, 'invitation_not_pending');
        final result = await repository.respondToInvitation(
          'inv-1',
          accept: true,
        );
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const RequestUnavailableFailure()),
        );
      });

      test('an ended session stays an ended session', () async {
        remote.error = _api(401, 'access_token_expired');
        final result = await repository.respondToRequest('in-1', accept: true);
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const SessionExpiredFailure()),
        );
      });
    });

    group('finishing a request the patient agreed to', () {
      final CompleteCircleRequest basics = CompleteCircleRequest(
        birthDate: DateTime(1954, 6, 5),
        city: 'بريدة',
      );

      test('creates the circle and sends the data for this request', () async {
        final result = await repository.completeRequest('in-1', basics);
        result.when(
          (circle) {
            expect(circle.id, 'circle-9');
            expect(circle.name, 'أمي نورة');
          },
          (failure) => fail('Expected a circle, got $failure'),
        );
        expect(remote.completedId, 'in-1');
        expect(remote.completedBody!['birth_date'], '1954-06-05');
        expect(remote.completedBody!['city'], 'بريدة');
      });

      test('a request that is gone is "no longer available"', () async {
        remote.error = _api(422, 'request_not_pending');
        final result = await repository.completeRequest('in-1', basics);
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const RequestUnavailableFailure()),
        );
      });

      test('a person who got a circle meanwhile is told so', () async {
        remote.error = _api(422, 'already_has_circle');
        final result = await repository.completeRequest('in-1', basics);
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const AlreadyHasCircleFailure()),
        );
      });
    });

    group('canceling a request', () {
      test('cancels this request', () async {
        final result = await repository.cancelRequest('request-1');
        expect(result.isSuccess(), isTrue);
        expect(remote.canceledId, 'request-1');
      });

      test('a request that cannot be canceled is "no longer available"',
          () async {
        remote.error = _api(422, 'request_not_cancelable');
        final result = await repository.cancelRequest('request-1');
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const RequestUnavailableFailure()),
        );
      });
    });

    group('deleting the account', () {
      test('sends the choices that were made', () async {
        const AccountDeletion choices = AccountDeletion(
          patientChoice: PatientChoice.keep,
          deleteLastManagedCircles: true,
        );
        final result = await repository.deleteAccount(choices);
        expect(result.isSuccess(), isTrue);
        expect(remote.sentDeletion, choices);
      });

      test('patient_choice_required asks for the choice', () async {
        remote.error = _api(422, 'patient_choice_required');
        final result = await repository.deleteAccount(const AccountDeletion());
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const PatientChoiceRequiredFailure()),
        );
      });

      test('last_manager asks about the circles with no other manager',
          () async {
        remote.error = _api(422, 'last_manager');
        final result = await repository.deleteAccount(const AccountDeletion());
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const LastManagerFailure()),
        );
      });

      test('another error is read like any other API error', () async {
        remote.error = _api(500, 'internal_error');
        final result = await repository.deleteAccount(const AccountDeletion());
        result.when(
          (_) => fail('Expected a failure'),
          (failure) => expect(failure, const ServerFailure()),
        );
      });
    });

    test('another 422 is read like any other API error', () async {
      remote.error = _api(422, 'validation_error');
      final result = await repository.createSelfCircle(_circle());
      result.when(
        (_) => fail('Expected a failure'),
        (failure) => expect(failure, const ValidationFailure()),
      );
    });

    test('an ended session stays an ended session', () async {
      remote.error = _api(401, 'access_token_expired');
      final result = await repository.createSelfCircle(_circle());
      result.when(
        (_) => fail('Expected a failure'),
        (failure) => expect(failure, const SessionExpiredFailure()),
      );
    });

    test('a failure to load the account is a failure, not a crash', () async {
      remote.error = DioException(
        requestOptions: RequestOptions(path: '/accounts/me'),
        type: DioExceptionType.connectionError,
      );
      final result = await repository.getAccount();
      result.when(
        (_) => fail('Expected a failure'),
        (failure) => expect(failure, const NetworkFailure()),
      );
    });
  });

  test('core registration resolves the circles dependency chain', () async {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:5000');
    try {
      await configureDependencies();
      expect(GetIt.I<CirclesUseCase>(), isA<CirclesUseCase>());
    } finally {
      await GetIt.I.reset();
    }
  });
}
