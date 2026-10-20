// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/network/dio_client.dart' as _i602;
import 'package:app/features/onboarding/data/datasources/onboarding_remote_data_source.dart'
    as _i734;
import 'package:app/features/onboarding/data/repositories/onboarding_repository_data.dart'
    as _i327;
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart'
    as _i95;
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart'
    as _i437;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initOnboarding({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i734.BaseOnboardingRemoteDataSource>(
      () => _i734.OnboardingRemoteDataSource(gh<_i602.DioClient>()),
    );
    gh.lazySingleton<_i95.OnboardingRepositoryDomain>(
      () => _i327.OnboardingRepositoryData(
        gh<_i734.BaseOnboardingRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i437.OnboardingUseCase>(
      () => _i437.OnboardingUseCase(gh<_i95.OnboardingRepositoryDomain>()),
    );
    return this;
  }
}
