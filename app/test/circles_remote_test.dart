import 'package:app/core/network/dio_client.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/models/complete_circle_request_model.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// One call as the data source made it.
class _Call {
  const _Call(this.method, this.path, this.data);

  final String method;
  final String path;
  final Object? data;
}

/// Stands in for the Dio client: records the calls and answers with a body
/// set by the test.
class _FakeClient extends Fake implements DioClient {
  final List<_Call> calls = <_Call>[];
  Object? answer = <String, dynamic>{};

  Response<dynamic> _response(String path) => Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: answer,
  );

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    calls.add(_Call('GET', path, null));
    return _response(path);
  }

  @override
  Future<Response<dynamic>> post(String path, {dynamic data}) async {
    calls.add(_Call('POST', path, data));
    return _response(path);
  }

  @override
  Future<Response<dynamic>> put(String path, {dynamic data}) async {
    calls.add(_Call('PUT', path, data));
    return _response(path);
  }

  @override
  Future<Response<dynamic>> patch(String path, {dynamic data}) async {
    calls.add(_Call('PATCH', path, data));
    return _response(path);
  }

  @override
  Future<Response<dynamic>> delete(String path, {dynamic data}) async {
    calls.add(_Call('DELETE', path, data));
    return _response(path);
  }
}

Map<String, dynamic> _contact({String id = 'k-1', String name = 'خالد'}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'relation': 'son',
      'phone_number': '+966512345678',
    };

Map<String, dynamic> _medicalFile() => <String, dynamic>{
  'patient': <String, dynamic>{
    'first_name': 'نورة',
    'last_name': 'العتيبي',
    'birth_date': '1954-06-05',
    'city': 'بريدة',
    'latitude': 26.3,
    'longitude': 43.97,
    'has_account': false,
    'app_mode': null,
    'is_you': false,
  },
  'medical_profile': <String, dynamic>{
    'blood_type': 'O+',
    'conditions': <String, dynamic>{
      'status': 'listed',
      'codes': <String>['diabetes', 'other'],
      'other': 'نقرس',
    },
    'allergies': <String, dynamic>{
      'status': 'none',
      'medication': <String>[],
      'other_medication': null,
      'food': <String>[],
      'other_food': null,
    },
  },
  'emergency_contacts': <dynamic>[_contact()],
};

Map<String, dynamic> _request(String status) => <String, dynamic>{
  'request': <String, dynamic>{
    'id': 'r-1',
    'patient_phone_number': '+966501234567',
    'circle_label': 'أمي',
    'proposed_app_mode': 'simplified',
    'status': status,
  },
};

void main() {
  late _FakeClient client;
  late CirclesRemoteDataSource remote;

  setUp(() {
    client = _FakeClient();
    remote = CirclesRemoteDataSource(client);
  });

  test('reads the requests from GET /circle-requests', () async {
    client.answer = <String, dynamic>{
      'sent': <dynamic>[_request('pending')['request']],
      'received': <dynamic>[],
    };
    final requests = await remote.getCircleRequests();
    expect(client.calls.single.method, 'GET');
    expect(client.calls.single.path, '/circle-requests');
    expect(requests.sent.single.id, 'r-1');
  });

  test('reads the invitations from GET /invitations', () async {
    client.answer = <String, dynamic>{
      'invitations': <dynamic>[
        <String, dynamic>{'id': 'i-1', 'circle_name': 'أمي نورة'},
      ],
    };
    final invitations = await remote.getInvitations();
    expect(client.calls.single.method, 'GET');
    expect(client.calls.single.path, '/invitations');
    expect(invitations.single.circleName, 'أمي نورة');
  });

  group('answering a request', () {
    test('sends the answer to the respond route of this request', () async {
      client.answer = _request('accepted');
      final answer = await remote.respondToRequest('r-1', accept: true);
      final _Call call = client.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/circle-requests/r-1/respond');
      expect(call.data, <String, dynamic>{'accept': true});
      expect(answer.toEntity().id, 'r-1');
    });

    test('sends "false" when the patient declines', () async {
      client.answer = _request('declined');
      await remote.respondToRequest('r-1', accept: false);
      expect(client.calls.single.data, <String, dynamic>{'accept': false});
    });
  });

  group('answering an invitation', () {
    test('accepting gives back the id of the circle', () async {
      client.answer = <String, dynamic>{
        'invitation': <String, dynamic>{'id': 'i-1', 'care_circle_id': 'c-1'},
      };
      final String? circleId = await remote.respondToInvitation(
        'i-1',
        accept: true,
      );
      final _Call call = client.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/invitations/i-1/respond');
      expect(call.data, <String, dynamic>{'accept': true});
      expect(circleId, 'c-1');
    });

    test('declining gives back no circle', () async {
      client.answer = <String, dynamic>{
        'invitation': <String, dynamic>{'id': 'i-1', 'care_circle_id': null},
      };
      expect(await remote.respondToInvitation('i-1', accept: false), isNull);
      expect(client.calls.single.data, <String, dynamic>{'accept': false});
    });
  });

  test('completing posts the basic data to the complete route', () async {
    client.answer = <String, dynamic>{
      'circle': <String, dynamic>{'id': 'c-9', 'name': 'أمي نورة'},
    };
    final circle = await remote.completeRequest(
      'r-1',
      CompleteCircleRequestModel(
        CompleteCircleRequest(birthDate: DateTime(1954, 6, 5), city: 'بريدة'),
      ),
    );
    final _Call call = client.calls.single;
    expect(call.method, 'POST');
    expect(call.path, '/circle-requests/r-1/complete');
    expect(call.data, <String, dynamic>{
      'birth_date': '1954-06-05',
      'city': 'بريدة',
    });
    expect(circle.toEntity().id, 'c-9');
  });

  test('canceling sends DELETE to this request', () async {
    await remote.cancelRequest('r-1');
    final _Call call = client.calls.single;
    expect(call.method, 'DELETE');
    expect(call.path, '/circle-requests/r-1');
    expect(call.data, isNull);
  });

  group('deleting the account', () {
    test('an account with no choices sends no body', () async {
      await remote.deleteAccount(const AccountDeletion());
      final _Call call = client.calls.single;
      expect(call.method, 'DELETE');
      expect(call.path, '/accounts/me');
      expect(call.data, isNull);
    });

    test('keeping the circle is written as "continue"', () async {
      await remote.deleteAccount(
        const AccountDeletion(patientChoice: PatientChoice.keep),
      );
      expect(client.calls.single.data, <String, dynamic>{
        'patient_choice': 'continue',
      });
    });

    test('deleting the circle is written as "delete"', () async {
      await remote.deleteAccount(
        const AccountDeletion(patientChoice: PatientChoice.delete),
      );
      expect(client.calls.single.data, <String, dynamic>{
        'patient_choice': 'delete',
      });
    });

    test('both choices are sent together', () async {
      await remote.deleteAccount(
        const AccountDeletion(
          patientChoice: PatientChoice.keep,
          deleteLastManagedCircles: true,
        ),
      );
      expect(client.calls.single.data, <String, dynamic>{
        'patient_choice': 'continue',
        'delete_last_managed_circles': true,
      });
    });

    test('agreeing to delete the circles with no other manager is sent alone', () async {
      await remote.deleteAccount(
        const AccountDeletion(deleteLastManagedCircles: true),
      );
      expect(client.calls.single.data, <String, dynamic>{
        'delete_last_managed_circles': true,
      });
    });
  });

  group('the medical file', () {
    test('reads the whole file from GET /circles/{id}/medical-profile', () async {
      client.answer = _medicalFile();

      final file = await remote.getMedicalFile('c-1');

      final _Call call = client.calls.single;
      expect(call.method, 'GET');
      expect(call.path, '/circles/c-1/medical-profile');
      expect(file.patient.fullName, 'نورة العتيبي');
      expect(file.patient.birthDate, DateTime(1954, 6, 5));
      expect(file.patient.city, 'بريدة');
      expect(file.patient.latitude, 26.3);
      expect(file.patient.hasAccount, isFalse);
      expect(file.profile.bloodType, 'O+');
      expect(
        file.profile.conditions,
        const ConditionsDraft.listed(
          codes: <String>['diabetes', 'other'],
          other: 'نقرس',
        ),
      );
      expect(file.profile.allergies, const AllergiesDraft.none());
      expect(file.contacts.single.name, 'خالد');
      expect(file.contacts.single.phoneNumber, '+966512345678');
    });

    test('a part that nobody answered is read as no answer', () async {
      client.answer = _medicalFile()
        ..['medical_profile'] = <String, dynamic>{
          'blood_type': null,
          'conditions': <String, dynamic>{
            'status': 'unknown',
            'codes': <String>[],
            'other': null,
          },
          'allergies': <String, dynamic>{
            'status': 'unknown',
            'medication': <String>[],
            'other_medication': null,
            'food': <String>[],
            'other_food': null,
          },
        };

      final file = await remote.getMedicalFile('c-1');

      expect(file.profile.isEmpty, isTrue);
    });

    test('saves the health answers with PATCH and sends every part', () async {
      client.answer = <String, dynamic>{
        'medical_profile': _medicalFile()['medical_profile'],
      };

      final saved = await remote.updateMedicalProfile(
        'c-1',
        const MedicalProfileDraft(
          bloodType: 'A-',
          conditions: ConditionsDraft.none(),
          allergies: AllergiesDraft.listed(
            medication: <String>['penicillin', 'other'],
            otherMedication: 'كوديين',
            food: <String>['milk'],
          ),
        ),
      );

      final _Call call = client.calls.single;
      expect(call.method, 'PATCH');
      expect(call.path, '/circles/c-1/medical-profile');
      expect(call.data, <String, dynamic>{
        'blood_type': 'A-',
        'conditions': <String, dynamic>{
          'status': 'none',
          'codes': <String>[],
          'other': null,
        },
        'allergies': <String, dynamic>{
          'status': 'listed',
          'medication': <String>['penicillin', 'other'],
          'other_medication': 'كوديين',
          'food': <String>['milk'],
          'other_food': null,
        },
      });
      expect(saved.bloodType, 'O+');
    });

    test('a part with no answer is sent as null, which clears it', () async {
      client.answer = <String, dynamic>{
        'medical_profile': _medicalFile()['medical_profile'],
      };

      await remote.updateMedicalProfile('c-1', const MedicalProfileDraft());

      expect(client.calls.single.data, <String, dynamic>{
        'blood_type': null,
        'conditions': null,
        'allergies': null,
      });
    });
  });

  group('the basic data of the patient', () {
    test('a patient without an account is saved with the names', () async {
      await remote.updatePatient(
        'c-1',
        PatientUpdate(
          birthDate: DateTime(1954, 6, 5),
          city: 'بريدة',
          firstName: 'نورة',
          lastName: 'العتيبي',
        ),
      );

      final _Call call = client.calls.single;
      expect(call.method, 'PUT');
      expect(call.path, '/circles/c-1/patient');
      expect(call.data, <String, dynamic>{
        'birth_date': '1954-06-05',
        'city': 'بريدة',
        'first_name': 'نورة',
        'last_name': 'العتيبي',
        'latitude': null,
        'longitude': null,
      });
    });

    test('a patient with an account is saved without the names', () async {
      await remote.updatePatient(
        'c-1',
        PatientUpdate(
          birthDate: DateTime(1954, 6, 5),
          city: 'بريدة',
          latitude: 26.3,
          longitude: 43.97,
        ),
      );

      expect(client.calls.single.data, <String, dynamic>{
        'birth_date': '1954-06-05',
        'city': 'بريدة',
        'latitude': 26.3,
        'longitude': 43.97,
      });
    });
  });

  group('the emergency contacts', () {
    const ContactDraft draft = ContactDraft(
      name: 'خالد',
      relation: 'son',
      phoneNumber: '+966512345678',
    );
    const Map<String, dynamic> body = <String, dynamic>{
      'name': 'خالد',
      'relation': 'son',
      'phone_number': '+966512345678',
    };

    test('adds a contact with POST', () async {
      client.answer = <String, dynamic>{'emergency_contact': _contact()};

      final EmergencyContact added = await remote.addContact('c-1', draft);

      final _Call call = client.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/circles/c-1/emergency-contacts');
      expect(call.data, body);
      expect(added.id, 'k-1');
    });

    test('changes a contact with PUT on the contact', () async {
      client.answer = <String, dynamic>{
        'emergency_contact': _contact(name: 'خالد الجديد'),
      };

      final EmergencyContact changed = await remote.updateContact(
        'c-1',
        'k-1',
        draft,
      );

      final _Call call = client.calls.single;
      expect(call.method, 'PUT');
      expect(call.path, '/circles/c-1/emergency-contacts/k-1');
      expect(call.data, body);
      expect(changed.name, 'خالد الجديد');
    });

    test('removes a contact with DELETE on the contact', () async {
      await remote.deleteContact('c-1', 'k-1');

      final _Call call = client.calls.single;
      expect(call.method, 'DELETE');
      expect(call.path, '/circles/c-1/emergency-contacts/k-1');
      expect(call.data, isNull);
    });
  });

  test('reads the emergency card from GET /circles/{id}/emergency-card', () async {
    client.answer = <String, dynamic>{
      'emergency_card': <String, dynamic>{
        'first_name': 'نورة',
        'last_name': 'العتيبي',
        ...(_medicalFile()['medical_profile'] as Map<String, dynamic>),
        'emergency_contacts': <dynamic>[_contact()],
      },
    };

    final card = await remote.getEmergencyCard('c-1');

    final _Call call = client.calls.single;
    expect(call.method, 'GET');
    expect(call.path, '/circles/c-1/emergency-card');
    expect(card.fullName, 'نورة العتيبي');
    expect(card.profile.bloodType, 'O+');
    expect(card.profile.allergies, const AllergiesDraft.none());
    expect(card.contacts.single.relation, 'son');
  });
}
