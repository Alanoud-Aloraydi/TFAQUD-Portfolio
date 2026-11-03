import 'package:app/core/di/configure_dependencies.config.dart';
import 'package:app/features/auth/di/auth_di.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/data/appointment_remote_data_source.dart';
import 'package:app/features/appointments/data/visit_remote_data_source.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/circles/di/circles_di.dart';
import 'package:app/features/home/di/home_di.dart';
import 'package:app/features/medications/di/medications_di.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/onboarding/di/onboarding_di.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  generateForDir: ['lib/core'],
)
Future<void> configureDependencies() async {
  final getIt = GetIt.instance;
  getIt.init();
  configureAuth(getIt);
  configureOnboarding(getIt);
  configureHome(getIt);
  configureCircles(getIt);
  configureMedications(getIt);
  getIt.registerLazySingleton<PrayerTimesRepository>(
    () =>
        PrayerTimesRepository(PrayerTimesRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<MeasurementRepository>(
    () => MeasurementRepository(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<AppointmentRepository>(
    () =>
        AppointmentRepository(AppointmentRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<VisitRepository>(
    () => VisitRepository(VisitRemoteDataSource(getIt<DioClient>())),
  );
}
