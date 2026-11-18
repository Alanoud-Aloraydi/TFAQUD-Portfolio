import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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
