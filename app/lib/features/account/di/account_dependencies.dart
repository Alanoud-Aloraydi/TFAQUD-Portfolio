import 'package:app/core/network/dio_client.dart';
import 'package:app/features/account/data/datasources/profile_remote_data_source.dart';
import 'package:app/features/account/data/repositories/profile_repository_impl.dart';
import 'package:app/features/account/domain/repositories/profile_repository.dart';
import 'package:app/features/account/domain/usecases/profile_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the account feature's profile data source, repository and use
/// case in [GetIt]. Called once at start-up by `configureDependencies` in
/// app/bootstrap.dart.
void registerAccountDependencies(GetIt getIt) {
  getIt.registerLazySingleton<BaseProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<BaseProfileRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ProfileUseCase>(
    () => ProfileUseCase(getIt<ProfileRepository>()),
  );
}
