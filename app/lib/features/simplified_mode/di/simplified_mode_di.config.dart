// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/services/calendar_sync.dart' as _i298;
import 'package:app/features/appointments/data/appointment_repository.dart'
    as _i125;
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart'
    as _i249;
import 'package:app/features/home/domain/use_cases/home_use_case.dart' as _i157;
import 'package:app/features/measurements/data/measurement_repository.dart'
    as _i531;
import 'package:app/features/medications/domain/dose_reminders.dart' as _i952;
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart'
    as _i560;
import 'package:app/features/prayer_times/data/prayer_times_repository.dart'
    as _i367;
import 'package:app/features/simplified_mode/data/simplified_preferences.dart'
    as _i662;
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart'
    as _i296;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initSimplifiedMode({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i662.SimplifiedPreferences>(
      () => _i662.SimplifiedPreferences(),
    );
    gh.lazySingleton<_i296.SimplifiedModeUseCase>(
      () => _i296.SimplifiedModeUseCase(
        gh<_i157.HomeUseCase>(),
        gh<_i560.MedicationsUseCase>(),
        gh<_i531.MeasurementRepository>(),
        gh<_i125.AppointmentRepository>(),
        gh<_i249.CirclesUseCase>(),
        gh<_i367.PrayerTimesRepository>(),
        gh<_i952.DoseReminders>(),
        gh<_i298.CalendarSync>(),
        gh<_i662.SimplifiedPreferences>(),
      ),
    );
    return this;
  }
}
