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
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/dose_reminder_texts.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:app/features/simplified_mode/di/simplified_mode_di.dart';

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
  getIt.registerLazySingleton<PrivatePhotoRepository>(
    () => PrivatePhotoRepository(getIt<DioClient>(), getIt<TokenStorage>()),
    dispose: (repository) => repository.dispose(),
  );
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
  // The notifications set on the phone, and the dose reminders that use
  // them.
  getIt.registerLazySingleton<PhoneNotifications>(PluginPhoneNotifications.new);
  getIt.registerLazySingleton<DoseReminders>(
    () => DoseReminders(
      getIt<MedicationsUseCase>(),
      getIt<PhoneNotifications>(),
      texts: doseReminderTexts,
    ),
  );
  // Optional mirror of doses, measurements and appointments onto the
  // phone's own Calendar app; off until the person turns it on.
  getIt.registerLazySingleton<CalendarSync>(
    () => CalendarSync(
      getIt<MedicationsUseCase>(),
      getIt<MeasurementRepository>(),
      getIt<AppointmentRepository>(),
    ),
  );
  // Circle updates from the server (Apple push, with the paid account).
  getIt.registerLazySingleton<PushRegistration>(
    () => PushRegistration(
      getIt<PhoneNotifications>(),
      (String token) => getIt<DioClient>().put(
        ApiEndpoints.pushDevice,
        data: <String, String>{'token': token},
      ),
    ),
  );
  configureSimplifiedMode(getIt);
}
