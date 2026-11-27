import 'dart:async';

import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/push_registration.dart';
import 'package:app/app/services/push_target.dart';
import 'package:app/app/services/reminders/arabic_reminder_texts.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/app/services/remote_push.dart';
import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/core/utils/device_zone.dart';
import 'package:app/core/utils/shown_circle_clock.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/auth/data/datasources/intro_memory.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/home/data/datasources/record_pdf_exporter.dart';
import 'package:app/features/home/domain/repositories/record_exporter.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Registers the services the whole app shares that no feature owns: the
/// care record's PDF, the memory of the welcome pages, the clock a circle
/// is shown in, the private photos, the weather and the phone's zone (the
/// circles' new patients and the account's city).
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
  getIt.registerLazySingleton<DeviceZone>(PluginDeviceZone.new);
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

/// The OneSignal app the pushes come from; no secret (sending needs a key).
const String oneSignalAppId = '50e5581f-1938-47b7-a23a-c65c70c4a26d';

/// [RemotePush] through the OneSignal SDK (onesignal_flutter). On a platform
/// OneSignal has no SDK for (web, desktop) every call does nothing.
class OneSignalRemotePush implements RemotePush {
  /// Each observer given, by the SDK observer that wraps it (kept alive).
  final Map<RemotePushObserver, OnPushSubscriptionChangeObserver> _observers =
      <RemotePushObserver, OnPushSubscriptionChangeObserver>{};
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _started = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<void> initialize() async {
    if (_started || !_supported) return;
    _started = true;
    // Everything in a debug build, only errors in the app people use.
    await OneSignal.Debug.setLogLevel(
      kDebugMode ? OSLogLevel.verbose : OSLogLevel.error,
    );
    await OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent tap) {
      final Map<String, dynamic>? data = tap.notification.additionalData;
      final String? text = pushTapText(data, action: tap.result.actionId);
      if (text != null) _taps.add(text);
    });
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> signIn(String accountId) async {
    if (_started) await OneSignal.login(accountId);
  }

  @override
  Future<void> signOut() async {
    if (_started) await OneSignal.logout();
  }

  @override
  String? get subscriptionId =>
      _started ? OneSignal.User.pushSubscription.id : null;

  @override
  bool get receivesPushes =>
      _started && (OneSignal.User.pushSubscription.optedIn ?? false);

  @override
  void addSubscriptionObserver(RemotePushObserver observer) {
    if (!_started || _observers.containsKey(observer)) return;
    void changed(OSPushSubscriptionChangedState state) =>
        observer(state.current.id);
    _observers[observer] = changed;
    OneSignal.User.pushSubscription.addObserver(changed);
  }

  @override
  void removeSubscriptionObserver(RemotePushObserver observer) {
    if (_observers.remove(observer) case final changed?) {
      OneSignal.User.pushSubscription.removeObserver(changed);
    }
  }

  @override
  Future<bool> requestPermission() async =>
      _started && await OneSignal.Notifications.requestPermission(true);

  @override
  Future<void> setWanted(bool wanted) async {
    if (!_started) return;
    final push = OneSignal.User.pushSubscription;
    if (!wanted) return push.optOut();
    // optIn would ask for a permission the phone lacks; the switch asks.
    if (OneSignal.Notifications.permission) await push.optIn();
  }
}
