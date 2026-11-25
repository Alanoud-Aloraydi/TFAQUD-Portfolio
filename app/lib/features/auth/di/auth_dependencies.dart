import 'package:app/core/network/dio_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

/// Registers the auth feature in [GetIt]: its data
/// sources, repositories and use cases.
void registerAuthDependencies(GetIt getIt) {
  getIt.registerLazySingleton<BaseAuthRemoteDataSource>(
    () =>
        AuthRemoteDataSource(getIt<DioClient>(), getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<BaseAuthRemoteDataSource>(),
      getIt<TokenStorage>(),
    ),
  );
  getIt.registerLazySingleton<AuthUseCase>(
    () => AuthUseCase(getIt<AuthRepository>()),
  );
}
