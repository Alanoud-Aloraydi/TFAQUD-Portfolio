import 'package:app/core/network/dio_client.dart';
import 'package:app/features/medications/data/datasources/medications_remote_data_source.dart';
import 'package:app/features/medications/data/repositories/medications_repository_impl.dart';
import 'package:app/features/medications/domain/repositories/medications_repository.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the medications feature in [GetIt]: its data
/// sources, repositories and use cases.
void registerMedicationsDependencies(GetIt getIt) {
  getIt.registerLazySingleton<BaseMedicationsRemoteDataSource>(
    () => MedicationsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<MedicationsRepository>(
    () => MedicationsRepositoryImpl(getIt<BaseMedicationsRemoteDataSource>()),
  );
  getIt.registerLazySingleton<MedicationsUseCase>(
    () => MedicationsUseCase(getIt<MedicationsRepository>()),
  );
}
