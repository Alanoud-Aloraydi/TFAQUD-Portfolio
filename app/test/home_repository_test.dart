import 'package:app/core/di/configure_dependencies.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/data/datasources/home_local_data_source.dart';
import 'package:app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:app/features/home/data/models/home_model.dart';
import 'package:app/features/home/data/repositories/home_repository_data.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

class _Storage extends Fake implements GetStorage {
  final values = <String, dynamic>{};
  bool unavailable = false;

  @override
  T? read<T>(String key) {
    if (unavailable) throw StateError('Storage unavailable');
    return values[key] as T?;
  }

  @override
  Future<void> write(String key, dynamic value) async {
    if (unavailable) throw StateError('Storage unavailable');
    values[key] = value;
  }
}

class _Remote extends Fake implements BaseHomeRemoteDataSource {
  Object? error;
  Map<String, dynamic> payload = {
    'account': {
      'id': 'account-a',
      'display_name': 'Nora',
      'profile_complete': true,
    },
    'care_circles': [
      {'id': 'circle-id', 'name': 'Care for Nora'},
    ],
  };

  @override
  Future<HomeModel> getHome() async {
    if (error != null) throw error!;
    return HomeModel.fromJson(payload);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Storage storage;
  late _Remote remote;
  late HomeRepositoryData repository;

  setUp(() {
    storage = _Storage();
    remote = _Remote();
    repository = HomeRepositoryData(remote, HomeLocalDataSource(storage));
  });

  test(
    'core registration resolves the complete home dependency chain',
    () async {
      dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:5000');
      try {
        await configureDependencies();
        await GetIt.I.unregister<GetStorage>();
        GetIt.I.registerSingleton<GetStorage>(storage);
        expect(GetIt.I<HomeUseCase>(), isA<HomeUseCase>());
      } finally {
        await GetIt.I.reset();
      }
    },
  );

  test(
    'maps UUID strings and account identity from the API contract',
    () async {
      final result = await repository.getHome();
      result.when((home) {
        expect(home.accountId, 'account-a');
        expect(home.displayName, 'Nora');
        expect(home.circles.single.id, 'circle-id');
        expect(() => home.circles.clear(), throwsUnsupportedError);
      }, (_) => fail('Expected a valid home response'));
    },
  );

  test('separate instances restore selection only for its account', () async {
    await repository.selectCircle('account-a', 'circle-id');
    final reopened = HomeRepositoryData(remote, HomeLocalDataSource(storage));
    expect(reopened.selectedCircle('account-a'), 'circle-id');
    expect(reopened.selectedCircle('account-b'), isNull);
    expect(storage.values.values, ['circle-id']);
  });

  test(
    'unavailable local storage does not prevent loading real circles',
    () async {
      storage.unavailable = true;
      expect(repository.selectedCircle('account-a'), isNull);
      expect((await repository.getHome()).isSuccess(), isTrue);
      final result = await repository.selectCircle('account-a', 'circle-id');
      result.when((_) => fail('Expected a storage failure'), (failure) {
        expect(failure, isA<CacheFailure>());
      });
    },
  );

  test(
    'a rejected session remains distinguishable from network failure',
    () async {
      remote.error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );
      final result = await repository.getHome();
      result.when((_) => fail('Expected authentication failure'), (failure) {
        expect(failure, isA<UnauthorizedFailure>());
      });
    },
  );

  test(
    'malformed API data becomes a failure instead of partial home data',
    () async {
      remote.payload = {'account': null, 'care_circles': []};
      expect((await repository.getHome()).isError(), isTrue);
    },
  );
}
