import 'package:app/app/di/services_dependencies.dart';
import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/storage/local_keys_service.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/account/di/account_dependencies.dart';
import 'package:app/features/appointments/di/appointments_dependencies.dart';
import 'package:app/features/auth/di/auth_dependencies.dart';
import 'package:app/features/circles/di/circles_dependencies.dart';
import 'package:app/features/home/di/home_dependencies.dart';
import 'package:app/features/measurements/di/measurements_dependencies.dart';
import 'package:app/features/medications/di/medications_dependencies.dart';
import 'package:app/features/prayer_times/di/prayer_times_dependencies.dart';
import 'package:app/features/simplified_mode/di/simplified_mode_dependencies.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

/// Registers everything the app needs in [GetIt], once at start-up:
/// storage and network first, then each feature, then the app services.
Future<void> configureDependencies() async {
  final GetIt getIt = GetIt.instance;
  _registerCore(getIt);
  registerAuthDependencies(getIt);
  registerAccountDependencies(getIt);
  registerHomeDependencies(getIt);
  registerCirclesDependencies(getIt);
  registerMedicationsDependencies(getIt);
  registerAppServices(getIt);
  registerPrayerTimesDependencies(getIt);
  registerMeasurementsDependencies(getIt);
  registerAppointmentsDependencies(getIt);
  registerReminderDependencies(getIt);
  registerPushDependencies(getIt);
  registerSimplifiedModeDependencies(getIt);
}

/// Local storage, the keychain, the session tokens and the API client.
void _registerCore(GetIt getIt) {
  getIt.registerLazySingleton<GetStorage>(GetStorage.new);
  // The keychain on iOS; the tokens live here, not in [GetStorage].
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(aOptions: AndroidOptions()),
  );
  getIt.registerLazySingleton<TokenStorage>(
    () => SecureTokenStorage(
      getIt<FlutterSecureStorage>(),
      getIt<LocalKeysService>(),
    ),
  );
  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(getIt<TokenStorage>()),
  );
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(getIt<AuthInterceptor>()),
  );
  getIt.registerSingleton<LocalKeysService>(LocalKeysService());
}
