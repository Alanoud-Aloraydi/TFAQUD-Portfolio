import 'package:app/core/network/dio_client.dart';
import 'package:app/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:app/features/prayer_times/domain/usecases/prayer_times_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the prayer times feature in [GetIt]: its repository and use
/// case.
void registerPrayerTimesDependencies(GetIt getIt) {
  getIt.registerLazySingleton<PrayerTimesRepository>(
    () => PrayerTimesRepositoryImpl(
      PrayerTimesRemoteDataSource(getIt<DioClient>()),
    ),
  );
  getIt.registerLazySingleton<PrayerTimesUseCase>(
    () => PrayerTimesUseCase(getIt<PrayerTimesRepository>()),
  );
}
