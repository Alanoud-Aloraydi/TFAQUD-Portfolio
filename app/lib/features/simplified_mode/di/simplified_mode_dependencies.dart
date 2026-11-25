import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/prayer_times/domain/usecases/prayer_times_use_case.dart';
import 'package:app/features/simplified_mode/data/datasources/simplified_preferences.dart';
import 'package:app/features/simplified_mode/data/repositories/simplified_reminders_impl.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the simplified mode feature in [GetIt]: its data
/// sources, repositories and use cases.
void registerSimplifiedModeDependencies(GetIt getIt) {
  getIt.registerLazySingleton<SimplifiedSettingsStore>(
    () => SimplifiedPreferences(),
  );
  getIt.registerLazySingleton<SimplifiedModeUseCase>(
    () => SimplifiedModeUseCase(
      getIt<HomeUseCase>(),
      getIt<MedicationsUseCase>(),
      getIt<MeasurementsUseCase>(),
      getIt<AppointmentsUseCase>(),
      getIt<CirclesUseCase>(),
      getIt<PrayerTimesUseCase>(),
      SimplifiedRemindersImpl(getIt<DoseReminders>(), getIt<CalendarSync>()),
    ),
  );
}
