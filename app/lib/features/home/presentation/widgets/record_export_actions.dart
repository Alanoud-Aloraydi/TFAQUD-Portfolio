import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/home/domain/entities/earliest_planned_day.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_document.dart';
import 'package:app/features/home/presentation/widgets/record_export_confirm.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the export sheet does with the choices it holds: the period they
/// make, picking a custom one, and sharing the record.
mixin RecordExportActions on State<RecordExportSheetBody> {
  abstract RecordExportOptions options;
  abstract ExportRange range;
  abstract ExportPeriod? custom;

  PatientClock get clock => PatientClockScope.of(context);

  ExportPeriod get period => ExportPeriod.of(
    range,
    today: clock.today(),
    earliest:
        earliestPlannedDay(widget.plans, widget.measurementPlans) ??
        clock.today(),
    custom: custom,
  );

  /// Picks [value] as the range; a custom range asks for its two days.
  Future<void> choose(ExportRange value) async {
    if (value != ExportRange.custom) return setState(() => range = value);
    final ExportPeriod? picked = await pickCustomExportPeriod(
      context,
      current: () => period,
      today: clock.today(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      custom = picked;
      range = ExportRange.custom;
    });
  }

  /// Reads the record, asks to confirm, shares it, and closes the sheet.
  Future<void> share() async {
    final cubit = context.read<RecordExportCubit>();
    final RecordExportData? data = await cubit.collect(
      options: options,
      period: period,
      clock: clock,
      plans: widget.plans,
    );
    if (data == null || !mounted) return;
    final bool shared = await confirmAndShareRecord(context, cubit, data);
    if (shared && mounted) Navigator.of(context).pop();
  }
}

/// Asks to confirm what [data] holds, then shares it as a PDF. Returns
/// whether the file was shared.
Future<bool> confirmAndShareRecord(
  BuildContext context,
  RecordExportCubit cubit,
  RecordExportData data,
) async {
  if (await showRecordExportConfirm(context, data) != true ||
      !context.mounted) {
    return false;
  }
  // Read now: the footer is written after the page has awaited.
  final String pageTemplate = context.tr('record_export.page');
  return cubit.share(
    document: buildRecordDocument(context, data),
    pageLabel: (page, pages) =>
        pageTemplate.replaceFirst('{}', '$page').replaceFirst('{}', '$pages'),
    filename: exportFilename(data.medicalFile?.patient.fullName, data.period),
  );
}
