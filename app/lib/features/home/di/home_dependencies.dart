import 'package:app/core/network/dio_client.dart';
import 'package:app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:app/features/home/data/repositories/home_repository_impl.dart';
import 'package:app/features/home/domain/repositories/home_repository.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

/// Registers the home feature in [GetIt]: its data
/// sources, repositories and use cases.
void registerHomeDependencies(GetIt getIt) {
  getIt.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSource(getIt<GetStorage>()),
  );
  getIt.registerLazySingleton<BaseHomeRemoteDataSource>(
    () => HomeRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      getIt<BaseHomeRemoteDataSource>(),
      getIt<HomeLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<HomeUseCase>(
    () => HomeUseCase(getIt<HomeRepository>()),
  );
}
