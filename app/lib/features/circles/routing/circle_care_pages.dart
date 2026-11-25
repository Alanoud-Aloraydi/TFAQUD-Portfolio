import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/pages/emergency_card_screen.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The medical file's edit page [screen] with its cubit. It starts from
/// the file the medical file page passes (no second read); opened from its
/// address alone, it reads the file.
Widget medicalFileEditPage(GoRouterState state, Widget screen) {
  return BlocProvider(
    create: (context) {
      final MedicalFileEditCubit cubit = MedicalFileEditCubit(
        GetIt.I<CirclesUseCase>(),
        state.pathParameters['circleId']!,
      );
      final Object? file = state.extra;
      if (file is MedicalFile) {
        cubit.start(file);
      } else {
        cubit.load();
      }
      return cubit;
    },
    child: screen,
  );
}

/// The emergency card of [circleId], with the medicines it lists;
/// [closeTo] is where «رجوع» goes when there is no page under it.
Widget emergencyCardPage(String circleId, String closeTo) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) =>
            EmergencyCardCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
      ),
      BlocProvider(
        create: (context) =>
            MedicationsCubit(GetIt.I<MedicationsUseCase>())..load(circleId),
      ),
    ],
    child: EmergencyCardScreen(closeTo: closeTo),
  );
}
