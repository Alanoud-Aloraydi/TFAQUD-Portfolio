import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/home/presentation/widgets/record_export_actions.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_content.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the export sheet holds while it is open: the period and the parts
/// of the record chosen. Needs a [RecordExportCubit] above it.
class RecordExportSheetBody extends StatefulWidget {
  const RecordExportSheetBody({
    super.key,
    required this.plans,
    required this.measurementPlans,
  });

  final List<MedicationPlan> plans;
  final List<MeasurementPlan> measurementPlans;

  @override
  State<RecordExportSheetBody> createState() => _RecordExportSheetBodyState();
}

class _RecordExportSheetBodyState extends State<RecordExportSheetBody>
    with RecordExportActions {
  @override
  RecordExportOptions options = const RecordExportOptions();
  @override
  ExportRange range = ExportRange.last30;
  @override
  ExportPeriod? custom;

  @override
  // The glass sheet draws the title and the line under it, and scrolls.
  Widget build(BuildContext context) =>
      BlocBuilder<RecordExportCubit, RecordExportState>(
        builder: (context, state) => RecordExportSheetContent(
          state: state,
          range: range,
          custom: custom,
          options: options,
          onRange: choose,
          onOptions: (value) => setState(() => options = value),
          onShare: share,
        ),
      );
}
