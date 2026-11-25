import 'package:app/app/router/medical_file_paths.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_screen.dart';
import 'package:app/features/circles/routing/circle_care_pages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The medical file of a circle, its edit page and its emergency card.
/// Each page loads what it shows from the server for the circle in the
/// address.
List<RouteBase> medicalFileRoutes() => <RouteBase>[
  GoRoute(
    path: MedicalFilePaths.medicalFilePath,
    pageBuilder: iosPage((context, state) {
      final String circleId = state.pathParameters['circleId']!;
      return BlocProvider(
        create: (context) =>
            MedicalFileCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
        child: MedicalFileScreen(circleId: circleId),
      );
    }),
  ),
  GoRoute(
    path: MedicalFilePaths.medicalFileEditPath,
    pageBuilder: iosPage(
      (context, state) =>
          medicalFileEditPage(state, const MedicalFileEditScreen()),
    ),
  ),
  GoRoute(
    path: MedicalFilePaths.emergencyCardPath,
    pageBuilder: iosPage(
      (context, state) =>
          emergencyCardPage(state.pathParameters['circleId']!, Routes.circle),
    ),
  ),
];
