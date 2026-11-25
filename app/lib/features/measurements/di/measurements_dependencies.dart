import 'package:app/core/network/dio_client.dart';
import 'package:app/features/measurements/data/repositories/measurements_repository_impl.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the measurements feature in [GetIt]: its repository and use
/// case.
void registerMeasurementsDependencies(GetIt getIt) {
  getIt.registerLazySingleton<MeasurementsRepository>(
    () => MeasurementsRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<MeasurementsUseCase>(
    () => MeasurementsUseCase(getIt<MeasurementsRepository>()),
  );
}
