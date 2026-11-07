// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/features/circles/domain/use_cases/circles_use_case.dart'
    as _i249;
import 'package:app/features/home/domain/use_cases/home_use_case.dart' as _i157;
import 'package:app/features/measurements/data/measurement_repository.dart'
    as _i531;
import 'package:app/features/medications/domain/dose_reminders.dart' as _i952;
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart'
    as _i560;
import 'package:app/features/simplified_mode/presentation/cubit/simplified_account_cubit.dart'
    as _i652;
import 'package:app/features/simplified_mode/presentation/cubit/simplified_home_cubit.dart'
    as _i567;
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart'
    as _i597;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initSimplifiedMode({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i652.SimplifiedAccountCubit>(
      () => _i652.SimplifiedAccountCubit(gh<_i157.HomeUseCase>()),
    );
    gh.factory<_i597.SimplifiedMeasurementCubit>(
      () => _i597.SimplifiedMeasurementCubit(gh<_i531.MeasurementRepository>()),
    );
    gh.factory<_i567.SimplifiedHomeCubit>(
      () => _i567.SimplifiedHomeCubit(
        gh<_i157.HomeUseCase>(),
        gh<_i560.MedicationsUseCase>(),
        gh<_i531.MeasurementRepository>(),
        gh<_i249.CirclesUseCase>(),
        gh<_i952.DoseReminders>(),
      ),
    );
    return this;
  }
}
