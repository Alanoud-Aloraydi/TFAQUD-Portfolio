import 'package:app/core/di/configure_dependencies.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/models/account_model.dart';
import 'package:app/features/circles/data/models/circle_model.dart';
import 'package:app/features/circles/data/models/new_self_circle_model.dart';
import 'package:app/features/circles/data/repositories/circles_repository_data.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/failures/circle_failures.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _Remote extends Fake implements BaseCirclesRemoteDataSource {
  Object? error;
  Map<String, dynamic>? sentBody;

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
}

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
