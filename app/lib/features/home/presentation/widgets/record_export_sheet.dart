import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:app/features/home/domain/export_filename.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/home/presentation/export/record_document.dart';
import 'package:app/features/home/presentation/widgets/record_export_confirm.dart';
import 'package:app/features/home/presentation/widgets/record_export_options_list.dart';
import 'package:app/features/home/presentation/widgets/record_export_range_field.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> showRecordExportSheet(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
  required List<MeasurementPlan> measurementPlans,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider(
    create: (_) => RecordExportCubit(
      GetIt.I<CirclesUseCase>(),
      RecordPdfExporter(),
      GetIt.I<MeasurementRepository>(),
      GetIt.I<MedicationsUseCase>(),
      GetIt.I<AppointmentRepository>(),
      GetIt.I<VisitRepository>(),
      circleId,
    )..load(),
    child: _RecordExportSheet(
      plans: List.unmodifiable(plans),
      measurementPlans: List.unmodifiable(measurementPlans),
    ),
  ),
);

class _RecordExportSheet extends StatefulWidget {
  const _RecordExportSheet({
    required this.plans,
    required this.measurementPlans,
  });

  final List<MedicationPlan> plans;
  final List<MeasurementPlan> measurementPlans;

  @override
  State<_RecordExportSheet> createState() => _RecordExportSheetState();
}

class _RecordExportSheetState extends State<_RecordExportSheet> {
  RecordExportOptions _options = const RecordExportOptions();
  ExportRange _range = ExportRange.last30;
  ExportPeriod? _custom;

  PatientClock get _clock => PatientClockScope.of(context);

  /// The first day anything was planned: where «السجل كاملًا» starts.
  DateTime get _earliest {
    final dates = <DateTime>[
      for (final plan in widget.plans) plan.version.startsOn,
      for (final plan in widget.measurementPlans)
        plan.history.first.effectiveFromOn,
    ]..sort();
    return dates.firstOrNull ?? _clock.today();
  }

  ExportPeriod get _period => ExportPeriod.of(
    _range,
    today: _clock.today(),
    earliest: _earliest,
    custom: _custom,
  );

  Future<void> _choose(ExportRange value) async {
    if (value != ExportRange.custom) return setState(() => _range = value);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: _clock.today(),
      initialDateRange: DateTimeRange(start: _period.start, end: _period.end),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _custom = ExportPeriod(picked.start, picked.end);
      _range = ExportRange.custom;
    });
  }

  Future<void> _share() async {
    final cubit = context.read<RecordExportCubit>();
    final RecordExportData? data = await cubit.collect(
      options: _options,
      period: _period,
      clock: _clock,
      plans: widget.plans,
    );
    if (data == null || !mounted) return;
    if (await showRecordExportConfirm(context, data) != true || !mounted) {
      return;
    }
    // Read now: the footer is written after the page has awaited.
    final String pageTemplate = context.tr('record_export.page');
    final bool shared = await cubit.share(
      document: buildRecordDocument(context, data),
      pageLabel: (page, pages) =>
          pageTemplate.replaceFirst('{}', '$page').replaceFirst('{}', '$pages'),
      filename: exportFilename(data.medicalFile?.patient.fullName, data.period),
    );
    if (shared && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: BlocBuilder<RecordExportCubit, RecordExportState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('record_export.title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                context.tr('record_export.subtitle'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              RecordExportRangeField(
                range: _range,
                custom: _custom,
                onSelected: _choose,
              ),
              const SizedBox(height: AppSpacing.md),
              RecordExportOptionsList(
                options: _options,
                hasMedicalFile: state.medicalFile != null,
                onChanged: (value) => setState(() => _options = value),
              ),
              if (state.errorKey != null) ...[
                const SizedBox(height: AppSpacing.sm),
                // Lined up with the text of the rows above.
                InsetText(
                  context.tr(state.errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed:
                    state.status == RecordExportStatus.ready &&
                        !state.busy &&
                        _options.hasAnySection
                    ? _share
                    : null,
                child: Text(context.tr('record_export.share')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
