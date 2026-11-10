// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/network/dio_client.dart' as _i602;
import 'package:app/features/account/data/datasources/profile_remote_data_source.dart'
    as _i355;
import 'package:app/features/account/data/repositories/profile_repository_data.dart'
    as _i766;
import 'package:app/features/account/domain/repositories/profile_repository_domain.dart'
    as _i394;
import 'package:app/features/account/domain/use_cases/profile_use_case.dart'
    as _i1064;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initAccount({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i355.BaseProfileRemoteDataSource>(
      () => _i355.ProfileRemoteDataSource(gh<_i602.DioClient>()),
    );
    gh.lazySingleton<_i394.ProfileRepositoryDomain>(
      () =>
          _i766.ProfileRepositoryData(gh<_i355.BaseProfileRemoteDataSource>()),
    );
    gh.lazySingleton<_i1064.ProfileUseCase>(
      () => _i1064.ProfileUseCase(gh<_i394.ProfileRepositoryDomain>()),
    );
    return this;
  }
}
