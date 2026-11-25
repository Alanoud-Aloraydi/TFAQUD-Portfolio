import 'package:app/core/network/dio_client.dart';
import 'package:app/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:app/features/appointments/data/datasources/visit_audio_service.dart';
import 'package:app/features/appointments/data/datasources/visit_remote_data_source.dart';
import 'package:app/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:app/features/appointments/domain/repositories/visit_audio.dart';
import 'package:app/features/appointments/domain/repositories/visits_repository.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/usecases/visits_use_case.dart';
import 'package:get_it/get_it.dart';

/// Registers the appointments feature in [GetIt]: appointments, visits and
/// the voice note of a visit.
void registerAppointmentsDependencies(GetIt getIt) {
  getIt.registerLazySingleton<AppointmentsRepository>(
    () => AppointmentsRepositoryImpl(
      AppointmentRemoteDataSource(getIt<DioClient>()),
    ),
  );
  getIt.registerLazySingleton<AppointmentsUseCase>(
    () => AppointmentsUseCase(getIt<AppointmentsRepository>()),
  );
  getIt.registerLazySingleton<VisitsRepository>(
    () => VisitsRepositoryImpl(VisitRemoteDataSource(getIt<DioClient>())),
  );
  getIt.registerLazySingleton<VisitsUseCase>(
    () => VisitsUseCase(getIt<VisitsRepository>()),
  );
  // One recorder per visit page, not one for the app: `VisitCubit.close`
  // disposes it. A shared recorder, disposed with the first page, left
  // every later page unable to record.
  getIt.registerFactory<VisitAudio>(VisitAudioService.new);
}
