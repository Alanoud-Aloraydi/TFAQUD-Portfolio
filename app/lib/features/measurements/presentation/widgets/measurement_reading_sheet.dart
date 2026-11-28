import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/measurements/domain/entities/measurement_conditions.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/invalid_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_layout.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
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
            create: (_) =>
                MeasurementRangesCubit(GetIt.I<MeasurementsRepository>())
                  ..load(context.read<MeasurementReadingsCubit>().circleId!),
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

/// The state of [MeasurementReadingSheet]: what it holds, what it does
/// with it, and the sheet it builds, each in its own mixin.
class MeasurementReadingSheetState extends State<MeasurementReadingSheet>
    with
        MeasurementReadingSheetScope,
        MeasurementReadingSheetValues,
        MeasurementReadingSheetSaving,
        MeasurementReadingSheetLayout {}

/// What the reading sheet makes of what is typed and chosen.
mixin MeasurementReadingSheetValues on MeasurementReadingSheetScope {
  /// The meal state chosen among the conditions, which picks the glucose
  /// range.
  String? get mealState => conditions
      .where(
        (code) => const <String>[
          'fasting',
          'before_meal',
          'after_meal',
          'bedtime',
        ].contains(code),
      )
      .firstOrNull;

  /// Where the typed value falls in [range]; null until it is a number.
  MeasurementLevel? levelIn(NormalRange range) {
    final int? one = int.tryParse(
      kind == MeasurementKind.bp ? systolic.text : glucose.text,
    );
    if (one == null || one < 1) return null;
    if (kind == MeasurementKind.glucose) return range.levelOf(one);
    final int? two = int.tryParse(diastolic.text);
    return two == null || two < 1 ? null : range.levelOf(one, two);
  }

  /// Switches to [value], keeping only the conditions it offers.
  void changeKind(MeasurementKind value) => setState(() {
    kind = value;
    // The numbers' message was about the other kind.
    if (isInvalidReadingKey(errorKey)) errorKey = null;
    // Fasting is not for blood pressure.
    final offered = MeasurementConditions.offered(value);
    conditions = [
      for (final code in conditions)
        if (offered.contains(code)) code,
    ];
  });
}
