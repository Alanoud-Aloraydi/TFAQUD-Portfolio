import 'package:app/core/network/dio_client.dart';
import 'package:app/core/utils/device_zone.dart';
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart';
import 'package:app/features/circles/data/repositories/circles_repository_impl.dart';
import 'package:app/features/circles/domain/repositories/circles_repository.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the circles feature in [GetIt]: its data
/// sources, repositories and use cases.
void registerCirclesDependencies(GetIt getIt) {
  getIt.registerLazySingleton<BaseCirclesRemoteDataSource>(
    () => CirclesRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<CirclesRepository>(
    () => CirclesRepositoryImpl(
      getIt<BaseCirclesRemoteDataSource>(),
      getIt<DeviceZone>(),
    ),
  );
  getIt.registerLazySingleton<CirclesUseCase>(
    () => CirclesUseCase(getIt<CirclesRepository>()),
  );
}
