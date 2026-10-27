// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/core/network/dio_client.dart' as _i602;
import 'package:app/features/medications/data/datasources/medications_remote_data_source.dart'
    as _i183;
import 'package:app/features/medications/data/repositories/medications_repository_data.dart'
    as _i473;
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart'
    as _i236;
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart'
    as _i560;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initMedications({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i183.BaseMedicationsRemoteDataSource>(
      () => _i183.MedicationsRemoteDataSource(gh<_i602.DioClient>()),
    );
    gh.lazySingleton<_i236.MedicationsRepositoryDomain>(
      () => _i473.MedicationsRepositoryData(
        gh<_i183.BaseMedicationsRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i560.MedicationsUseCase>(
      () => _i560.MedicationsUseCase(gh<_i236.MedicationsRepositoryDomain>()),
    );
    return this;
  }
}
