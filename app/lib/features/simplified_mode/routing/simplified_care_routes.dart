import 'package:app/app/router/medical_file_paths.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/app/services/shown_circle_clock.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/routing/circle_care_pages.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_medical_file_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_home_focus.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// A circle's emergency card and medical file inside the simplified shell.
List<RouteBase> simplifiedCareRoutes() => <RouteBase>[
  // The same card as the detailed mode's, but inside this shell and at
  // this mode's size, like the edit page below it: «رجوع» never lands
  // in the detailed mode.
  GoRoute(
    path: MedicalFilePaths.simplifiedEmergencyCardPath,
    pageBuilder: iosPage(
      (context, state) => SimplifiedDetailScale(
        child: emergencyCardPage(
          state.pathParameters['circleId']!,
          Routes.simplifiedMode,
        ),
      ),
    ),
  ),
  GoRoute(
    path: MedicalFilePaths.simplifiedMedicalFilePath,
    pageBuilder: iosPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (context) =>
            MedicalFileCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
        child: SimplifiedMedicalFileScreen(circleId: circleId),
      );
    }),
  ),
  // The detailed mode's edit page inside this shell, at this mode's
  // size: «حفظ» and «رجوع» return to the simplified medical file.
  GoRoute(
    path: MedicalFilePaths.simplifiedMedicalFileEditPath,
    pageBuilder: iosPage(
      (context, state) => medicalFileEditPage(
        state,
        SimplifiedDetailScale(
          child: MedicalFileEditScreen(
            savedTo: null,
            closeTo: Routes.simplifiedMedicalFile(
              state.pathParameters['circleId']!,
            ),
          ),
        ),
      ),
    ),
  ),
];

/// The one day ([SimplifiedModeCubit]) and the one text size every
/// simplified screen shares, above [child].
Widget simplifiedShellCubits({required Widget child}) => MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => SimplifiedModeCubit(
        GetIt.I<SimplifiedModeUseCase>(),
        photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
        shownClock: GetIt.I<ShownCircleClock>(),
      )..load(),
    ),
    BlocProvider(
      create: (context) =>
          SimplifiedSettingsCubit(GetIt.I<SimplifiedSettingsStore>())..load(),
    ),
  ],
  child: SimplifiedTextScale(child: child),
);
