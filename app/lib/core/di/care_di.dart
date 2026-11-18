import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/features/appointments/data/appointment_remote_data_source.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/data/visit_audio_service.dart';
import 'package:app/features/appointments/data/visit_remote_data_source.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository_domain.dart';
import 'package:app/features/appointments/domain/repositories/visits_repository_domain.dart';
import 'package:app/features/appointments/domain/services/visit_audio.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository_data.dart';
import 'package:app/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository_domain.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:get_it/get_it.dart';

/// The care features read from the server: prayer times, measurements and
/// the weather beside them, appointments and visits, each repository
/// behind its domain contract and its use case.
void configureCare(GetIt getIt) {
  getIt.registerLazySingleton<PrayerTimesRepositoryDomain>(
    () =>
        PrayerTimesRepository(PrayerTimesRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<PrayerTimesUseCase>(
    () => PrayerTimesUseCase(getIt<PrayerTimesRepositoryDomain>()),
  );
  getIt.registerLazySingleton<MeasurementRepository>(
    () => MeasurementRepositoryData(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<MeasurementsRepositoryDomain>(
    () => getIt<MeasurementRepository>(),
  );
  getIt.registerLazySingleton<WeatherSource>(AppleWeather.new);
  getIt.registerLazySingleton<MeasurementsUseCase>(
    () => MeasurementsUseCase(getIt<MeasurementsRepositoryDomain>()),
  );
  getIt.registerLazySingleton<AppointmentsRepositoryDomain>(
    () =>
        AppointmentRepository(AppointmentRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<AppointmentsUseCase>(
    () => AppointmentsUseCase(getIt<AppointmentsRepositoryDomain>()),
  );
  getIt.registerLazySingleton<VisitsRepositoryDomain>(
    () => VisitRepository(VisitRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<VisitsUseCase>(
    () => VisitsUseCase(getIt<VisitsRepositoryDomain>()),
  );
  // The microphone and the speaker behind the voice note of a visit. One
  // per visit page, not one for the app: `VisitCubit.close` disposes it,
  // and a shared recorder disposed with the first page left every later
  // page unable to record at all.
  getIt.registerFactory<VisitAudio>(VisitAudioService.new);
}
