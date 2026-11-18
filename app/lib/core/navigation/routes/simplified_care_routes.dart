import 'package:app/core/navigation/routers.dart';
import 'package:app/core/navigation/routes/circle_care_pages.dart';
import 'package:app/core/navigation/routes/page_builders.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_medical_file_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_detail_scale.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/medical_file_paths.dart';

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
