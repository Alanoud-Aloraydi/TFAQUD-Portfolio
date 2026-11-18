import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/features/auth/data/datasources/intro_memory.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:get_it/get_it.dart';

/// The services the whole app shares that no feature owns: the care
/// record's PDF, the memory of the welcome pages, the clock a circle is
/// shown in, and the private photos.
void configureAppServices(GetIt getIt) {
  // The care record, built as a PDF on the phone.
  getIt.registerLazySingleton<RecordExporter>(RecordPdfExporter.new);
  // Whether this install already showed the welcome pages.
  getIt.registerLazySingleton<WelcomeMemory>(IntroMemory.new);
  getIt.registerLazySingleton<ShownCircleClock>(ShownCircleClock.new);
  getIt.registerLazySingleton<PrivatePhotoRepository>(
    () => PrivatePhotoRepository(getIt<DioClient>(), getIt<TokenStorage>()),
    dispose: (repository) => repository.dispose(),
  );
}
