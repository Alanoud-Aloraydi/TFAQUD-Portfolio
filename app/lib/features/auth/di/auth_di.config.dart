// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/network/dio_client.dart' as _i602;
import 'package:app/core/services/token_storage.dart' as _i918;
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i992;
import 'package:app/features/auth/data/repositories/auth_repository_data.dart'
    as _i877;
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart'
    as _i419;
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart' as _i642;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initAuth({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i992.BaseAuthRemoteDataSource>(
      () => _i992.AuthRemoteDataSource(gh<_i602.DioClient>()),
    );
    gh.lazySingleton<_i419.AuthRepositoryDomain>(
      () => _i877.AuthRepositoryData(
        gh<_i992.BaseAuthRemoteDataSource>(),
        gh<_i918.TokenStorage>(),
      ),
    );
    gh.lazySingleton<_i642.AuthUseCase>(
      () => _i642.AuthUseCase(gh<_i419.AuthRepositoryDomain>()),
    );
    return this;
  }
}
