import 'package:app/core/di/configure_dependencies.config.dart';
import 'package:app/core/l10n/dose_reminder_texts.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_registration.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/features/account/di/account_di.dart';
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
import 'package:app/features/auth/data/datasources/intro_memory.dart';
import 'package:app/features/auth/di/auth_di.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/circles/di/circles_di.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:app/features/home/di/home_di.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/di/medications_di.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/prayer_times/data/prayer_times_remote_data_source.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository_domain.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/simplified_mode/di/simplified_mode_di.dart';
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
  configureAccount(getIt);
  configureHome(getIt);
  configureCircles(getIt);
  configureMedications(getIt);
  // The care record, built as a PDF on the phone.
  getIt.registerLazySingleton<RecordExporter>(RecordPdfExporter.new);
  // Whether this install already showed the welcome pages.
  getIt.registerLazySingleton<WelcomeMemory>(IntroMemory.new);
  getIt.registerLazySingleton<ShownCircleClock>(ShownCircleClock.new);
  getIt.registerLazySingleton<PrivatePhotoRepository>(
    () => PrivatePhotoRepository(getIt<DioClient>(), getIt<TokenStorage>()),
    dispose: (repository) => repository.dispose(),
  );
  getIt.registerLazySingleton<PrayerTimesRepositoryDomain>(
    () =>
        PrayerTimesRepository(PrayerTimesRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<PrayerTimesUseCase>(
    () => PrayerTimesUseCase(getIt<PrayerTimesRepositoryDomain>()),
  );
  getIt.registerLazySingleton<MeasurementRepository>(
    () => MeasurementRepository(getIt<DioClient>()),
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
  // The microphone and the speaker behind the voice note of a visit.
  getIt.registerLazySingleton<VisitAudio>(VisitAudioService.new);
  // The notifications set on the phone, and the reminders that use them:
  // doses, measurements and appointments.
  getIt.registerLazySingleton<PhoneNotifications>(PluginPhoneNotifications.new);
  getIt.registerLazySingleton<DoseReminders>(
    () => DoseReminders(
      getIt<MedicationsUseCase>(),
      getIt<PhoneNotifications>(),
      texts: doseReminderTexts,
      measurements: getIt<MeasurementsUseCase>(),
      appointments: getIt<AppointmentsUseCase>(),
      // «ذكّرني لاحقًا» goes to the whole circle.
      share: (SnoozeShare snooze) => getIt<DioClient>().put(
        ApiEndpoints.taskSnoozes(snooze.circleId),
        data: snooze.toJson(),
      ),
    ),
  );
  // Optional mirror of doses, measurements and appointments onto the
  // phone's own Calendar app, with the tasks put off at their new times;
  // off until the person turns it on.
  getIt.registerLazySingleton<CalendarSync>(
    () => CalendarSync(
      getIt<MedicationsUseCase>(),
      getIt<MeasurementsUseCase>(),
      getIt<AppointmentsUseCase>(),
      snoozes: getIt<DoseReminders>().snoozes,
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
