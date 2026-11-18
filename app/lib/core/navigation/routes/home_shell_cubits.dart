import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The cubits every home tab shares, above [child]. The home cubit loads
/// the circles. The inbox cubit counts what waits for an answer, for the
/// dot on the bell; it loads again whenever the circles change.
Widget homeShellCubits({required Widget child}) => MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => HomeCubit(
        GetIt.I<HomeUseCase>(),
        GetIt.I<PrivatePhotoRepository>().changes,
        GetIt.I<ShownCircleClock>(),
      )..load(),
    ),
    BlocProvider(
      create: (context) => InboxCubit(
        GetIt.I<CirclesUseCase>(),
        GetIt.I<HomeUseCase>(),
        followCircleChanges: true,
      )..load(),
    ),
    BlocProvider(
      create: (context) => MedicationsCubit(GetIt.I<MedicationsUseCase>()),
    ),
    BlocProvider(
      create: (context) => MedicationOccurrencesCubit(
        GetIt.I<MedicationsUseCase>(),
        photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
      ),
    ),
    BlocProvider(
      create: (context) =>
          MeasurementPlansCubit(GetIt.I<MeasurementsUseCase>()),
    ),
    BlocProvider(
      create: (context) => MeasurementTasksCubit(
        GetIt.I<MeasurementsUseCase>(),
        GetIt.I<PrivatePhotoRepository>().changes,
      ),
    ),
    BlocProvider(
      create: (context) => MeasurementReadingsCubit(
        GetIt.I<MeasurementsUseCase>(),
        GetIt.I<PrivatePhotoRepository>().changes,
      ),
    ),
    BlocProvider(
      create: (context) => AppointmentsCubit(GetIt.I<AppointmentsUseCase>()),
    ),
    BlocProvider(
      create: (context) => PrayerTimesCubit(GetIt.I<PrayerTimesUseCase>()),
    ),
  ],
  child: child,
);
