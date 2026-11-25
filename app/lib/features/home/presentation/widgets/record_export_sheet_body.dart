import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/features/home/domain/entities/earliest_planned_day.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/presentation/cubit/record_export_collecting.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_document.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_content.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
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

class _RecordExportSheetBodyState extends State<RecordExportSheetBody> {
  RecordExportOptions options = const RecordExportOptions();
  ExportRange range = ExportRange.last30;
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

/// A section as a row: a tap includes it or leaves it out, and a check at
/// its end marks it included, as in the app's other lists of choices. Null
/// [onChanged] greys it.
class RecordExportCheckRow extends StatelessWidget {
  const RecordExportCheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    return Semantics(
      checked: checked,
      enabled: enabled,
      child: InsetRow(
        label: label,
        labelColor: enabled ? null : AppSemanticColors.borderControlBase,
        // The words take the row; the check (or its room) sits at the end.
        leading: const SizedBox.shrink(),
        onTap: enabled ? () => onChanged!(!checked) : null,
        trailing: SizedBox.square(
          dimension: AppSizes.iconSmall,
          child: checked
              ? const Icon(
                  ActionIcons.check,
                  size: AppSizes.iconSmall,
                  color: AppSemanticColors.textPrimary,
                )
              : null,
        ),
      ),
    );
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

/// Shows what the file will hold before it is created. True when the person
/// agrees.
Future<bool?> showRecordExportConfirm(
  BuildContext context,
  RecordExportData data,
) {
  final int missed = data.missedDoses.length;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.tr('record_export.preview_title')),
      content: Text(
        context.tr(
          'record_export.preview_text',
          args: <String>[
            '${data.currentMedications}',
            '${data.doses.where((d) => d.record != null).length}',
            '$missed',
            '${data.takenReadings.length}',
            '${data.appointments.length}',
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr('record_export.create_file')),
        ),
      ],
    ),
  );
}

/// The app's own date wheel, twice: where the period starts, then where it
/// ends (never before its start, never after [today]). [current] is the
/// period chosen so far, which the wheels open on. Null when either wheel
/// is closed without a choice.
Future<ExportPeriod?> pickCustomExportPeriod(
  BuildContext context, {
  required ExportPeriod Function() current,
  required DateTime today,
}) async {
  final DateTime? start = await showTafaqodDateSheet(
    context,
    title: context.tr('record_export.custom_start'),
    initialDate: current().start,
    firstDate: DateTime(2000),
    lastDate: today,
    confirmLabel: context.tr('common.continue'),
  );
  if (start == null || !context.mounted) return null;
  final DateTime end0 = current().end.isBefore(start) ? start : current().end;
  final DateTime? end = await showTafaqodDateSheet(
    context,
    title: context.tr('record_export.custom_end'),
    initialDate: end0.isAfter(today) ? today : end0,
    firstDate: start,
    lastDate: today,
  );
  if (end == null) return null;
  return ExportPeriod(start, end);
}
