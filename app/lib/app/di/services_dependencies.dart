import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/one_signal_remote_push.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/push_registration.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/app/services/remote_push.dart';
import 'package:app/app/services/shown_circle_clock.dart';
import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/localization/dose_reminder_texts.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/auth/data/datasources/intro_memory.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/home/data/datasources/record_pdf_exporter.dart';
import 'package:app/features/home/domain/repositories/record_exporter.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the services the whole app shares that no feature owns: the
/// care record's PDF, the memory of the welcome pages, the clock a circle
/// is shown in, the private photos and the weather.
void registerAppServices(GetIt getIt) {
  // The care record, built as a PDF on the phone.
  getIt.registerLazySingleton<RecordExporter>(RecordPdfExporter.new);
  // Whether this install already showed the welcome pages.
  getIt.registerLazySingleton<WelcomeMemory>(IntroMemory.new);
  getIt.registerLazySingleton<ShownCircleClock>(ShownCircleClock.new);
  getIt.registerLazySingleton<PrivatePhotoRepository>(
    () => PrivatePhotoRepository(getIt<DioClient>(), getIt<TokenStorage>()),
    dispose: (repository) => repository.dispose(),
  );
  getIt.registerLazySingleton<WeatherSource>(AppleWeather.new);
}

/// Registers the server's pushes through OneSignal: [RemotePush] (the only
/// way into its SDK), and [PushRegistration], which links the signed-in
/// account to this phone and tells the server whether this phone gets the
/// server's reminders.
void registerPushDependencies(GetIt getIt) {
  getIt.registerLazySingleton<RemotePush>(OneSignalRemotePush.new);
  getIt.registerLazySingleton<PushRegistration>(
    () => PushRegistration(
      getIt<PhoneNotifications>(),
      remote: getIt<RemotePush>(),
      send: (String subscriptionId) async {
        final answer = await getIt<DioClient>().put(
          AccountEndpoints.pushSubscription,
          data: <String, Object>{
            'subscription_id': subscriptionId,
            // Only while OneSignal shows this phone the pushes: else the
            // phone keeps its own reminders.
            'server_reminders': getIt<RemotePush>().receivesPushes,
          },
        );
        await getIt<DoseReminders>().server.set(serverRemindsFrom(answer.data));
      },
    ),
  );
}

/// What the phone itself shows: its notifications, the reminders that use
/// them, and the optional mirror onto its Calendar app.
void registerReminderDependencies(GetIt getIt) {
  // The notifications set on the phone, and the reminders that use them:
  // doses, measurements and appointments.
  getIt.registerLazySingleton<PhoneNotifications>(
    () => PluginPhoneNotifications(pushTaps: getIt<RemotePush>().taps),
  );
  getIt.registerLazySingleton<DoseReminders>(
    () => DoseReminders(
      getIt<MedicationsUseCase>(),
      getIt<PhoneNotifications>(),
      texts: doseReminderTexts,
      measurements: getIt<MeasurementsUseCase>(),
      appointments: getIt<AppointmentsUseCase>(),
      // «ذكّرني لاحقًا» goes to the whole circle.
      share: (SnoozeShare snooze) => getIt<DioClient>().put(
        CircleEndpoints.taskSnoozes(snooze.circleId),
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
}
