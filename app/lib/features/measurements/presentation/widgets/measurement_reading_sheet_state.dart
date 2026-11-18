import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_layout.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_scope.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_sheet_values.dart';
import 'package:flutter/material.dart';

/// The state of [MeasurementReadingSheet]: what it holds, what it does
/// with it, and the sheet it builds, each in its own mixin.
class MeasurementReadingSheetState extends State<MeasurementReadingSheet>
    with
        MeasurementReadingSheetScope,
        MeasurementReadingSheetValues,
        MeasurementReadingSheetSaving,
        MeasurementReadingSheetLayout {}
