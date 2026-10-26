// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/network/dio_client.dart' as _i602;
import 'package:app/features/circles/data/datasources/circles_remote_data_source.dart'
    as _i411;
import 'package:app/features/circles/data/repositories/circles_repository_data.dart'
    as _i716;
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart'
    as _i283;
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart'
    as _i865;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initCircles({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i411.BaseCirclesRemoteDataSource>(
      () => _i411.CirclesRemoteDataSource(gh<_i602.DioClient>()),
    );
    gh.lazySingleton<_i283.CirclesRepositoryDomain>(
      () => _i716.CirclesRepositoryData(gh<_i411.BaseCirclesRemoteDataSource>()),
    );
    gh.lazySingleton<_i865.CirclesUseCase>(
      () => _i865.CirclesUseCase(gh<_i283.CirclesRepositoryDomain>()),
    );
    return this;
  }
}
