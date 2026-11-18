import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Opens «تسجيل قراءة» over [context], whose [MeasurementReadingsCubit]
/// saves it: the answer to [occurrence], the task the person chose, or a
/// free reading when it is null. True when a reading was saved.
Future<bool> showMeasurementReadingSheet(
  BuildContext context, {
  MeasurementOccurrence? occurrence,
}) async =>
    await showGlassSheet<bool>(
      context,
      title: context.tr('measurements.record_reading'),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<MeasurementReadingsCubit>()),
          BlocProvider(
            create: (_) => MeasurementRangesCubit(
              GetIt.I<MeasurementRepository>(),
              GetIt.I<CirclesUseCase>(),
            )..load(context.read<MeasurementReadingsCubit>().circleId!),
          ),
        ],
        child: MeasurementReadingSheet(occurrence: occurrence),
      ),
    ) ??
    false;

/// «تسجيل قراءة»: the values, conditions and time of one reading. A free
/// reading also picks its kind. «المعدل الطبيعي» under the values follows
/// the kind and the meal state chosen, and marks where the typed value
/// falls.
class MeasurementReadingSheet extends StatefulWidget {
  const MeasurementReadingSheet({super.key, this.occurrence});

  final MeasurementOccurrence? occurrence;

  @override
  State<MeasurementReadingSheet> createState() =>
      MeasurementReadingSheetState();
}
