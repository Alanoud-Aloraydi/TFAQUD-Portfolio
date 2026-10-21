// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/network/dio_client.dart' as _i602;
import 'package:app/features/home/data/datasources/home_local_data_source.dart'
    as _i609;
import 'package:app/features/home/data/datasources/home_remote_data_source.dart'
    as _i872;
import 'package:app/features/home/data/repositories/home_repository_data.dart'
    as _i651;
import 'package:app/features/home/domain/repositories/home_repository_domain.dart'
    as _i559;
import 'package:app/features/home/domain/use_cases/home_use_case.dart' as _i157;
import 'package:get_it/get_it.dart' as _i174;
import 'package:get_storage/get_storage.dart' as _i792;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initHome({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i609.HomeLocalDataSource>(
      () => _i609.HomeLocalDataSource(gh<_i792.GetStorage>()),
    );
    gh.lazySingleton<_i872.BaseHomeRemoteDataSource>(
      () => _i872.HomeRemoteDataSource(gh<_i602.DioClient>()),
    );
    gh.lazySingleton<_i559.HomeRepositoryDomain>(
      () => _i651.HomeRepositoryData(
        gh<_i872.BaseHomeRemoteDataSource>(),
        gh<_i609.HomeLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i157.HomeUseCase>(
      () => _i157.HomeUseCase(gh<_i559.HomeRepositoryDomain>()),
    );
    return this;
  }
}
