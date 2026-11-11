import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
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

enum _ExportMode { summary, detailed }

enum _ExportRange { last7, last30, last90, custom, all }

/// Renders the record export sheet element of record export sheet.
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
  bool _medical = true;
  bool _medications = true;
  bool _measurements = true;
  bool _appointments = true;
  bool _includeContacts = false;
  _ExportMode _mode = _ExportMode.summary;
  _ExportRange _range = _ExportRange.last30;
  DateTimeRange? _customRange;
  String? _errorKey;

  DateTime get _today => PatientClockScope.of(context).today();

  DateTime get _earliest {
    final dates = <DateTime>[
      for (final plan in widget.plans) plan.version.startsOn,
      for (final plan in widget.measurementPlans)
        plan.history.first.effectiveFromOn,
    ];
    if (dates.isEmpty) return _today;
    dates.sort();
    return dates.first;
  }

  DateTimeRange get _selectedRange {
    if (_range == _ExportRange.custom && _customRange != null) {
      return _customRange!;
    }
    final days = switch (_range) {
      _ExportRange.last7 => 6,
      _ExportRange.last30 => 29,
      _ExportRange.last90 => 89,
      _ExportRange.all => null,
      _ExportRange.custom => 29,
    };
    return DateTimeRange(
      start: days == null
          ? _earliest
          : DateTime(_today.year, _today.month, _today.day - days),
      end: _today,
    );
  }

  bool _within(DateTime value, DateTimeRange range) {
    final day = DateUtils.dateOnly(value);
    return !day.isBefore(DateUtils.dateOnly(range.start)) &&
        !day.isAfter(DateUtils.dateOnly(range.end));
  }

  Future<void> _share(RecordExportState state) async {
    final exporter = context.read<RecordExportCubit>();
    final file = state.medicalFile;
    if (_medical &&
        file == null &&
        !_medications &&
        !_measurements &&
        !_appointments) {
      return;
    }
    List<MeasurementReading> readings = const [];
    List<MeasurementOccurrence> measurementTasks = const [];
    List<DoseOccurrence> doses = const [];
    List<CareAppointment> appointments = const [];
    Map<String, VisitPaper> visits = const {};
    final range = _selectedRange;
    try {
      if (_medications) {
        doses = await exporter.medicationOccurrences(range.start, range.end);
      }
      if (_measurements) {
        readings = (await exporter.allMeasurements()).where((item) {
          final date = item.measuredAt ?? item.scheduledOn;
          return date != null && _within(date, range);
        }).toList();
        measurementTasks = await exporter.measurementOccurrences(
          range.start,
          range.end,
        );
      }
      if (_appointments) {
        appointments = (await exporter.allAppointments())
            .where((item) => _within(item.scheduledOn, range))
            .toList();
        if (_mode == _ExportMode.detailed) {
          visits = await exporter.allVisits(appointments);
        }
      }
    } on Exception {
      if (mounted) setState(() => _errorKey = 'record_export.failed');
      return;
    }
    if (!mounted) return;
    final confirmed = await _confirmSummary(
      doses,
      readings,
      measurementTasks,
      appointments,
    );
    if (confirmed != true || !mounted) return;
    final sections = <RecordPdfSection>[
      _summarySection(doses, readings, measurementTasks, appointments),
      if (_medical && file != null) _medicalSection(file),
      if (_medications) _medicationSection(widget.plans),
      if (_medications && _mode == _ExportMode.detailed) _doseSection(doses),
      if (_measurements) _measurementSection(readings),
      if (_measurements && _mode == _ExportMode.detailed)
        _missedMeasurementSection(measurementTasks),
      if (_appointments) _appointmentSection(appointments, visits),
    ];
    final String exportedOn = context.tr(
      'record_export.exported_on',
      args: <String>[
        formatBirthDate(context, PatientClockScope.of(context).today()),
      ],
    );
    // Read now: the footer is written after the page has awaited.
    final String pageTemplate = context.tr('record_export.page');
    final error = await exporter.share(
      title: context.tr('record_export.pdf_title'),
      subtitle: file == null
          ? '${_rangeText(range)} · $exportedOn'
          : '${file.patient.fullName} · ${_rangeText(range)} · $exportedOn',
      appName: context.tr('auth.app_name'),
      pageLabel: (int page, int pages) =>
          pageTemplate.replaceFirst('{}', '$page').replaceFirst('{}', '$pages'),
      sections: sections,
      filename: _filename(file?.patient.fullName, range),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _errorKey = error);
    }
  }

  String _rangeText(DateTimeRange range) =>
      '${formatBirthDate(context, range.start)} – '
      '${formatBirthDate(context, range.end)}';

  String _filename(String? patientName, DateTimeRange range) {
    final safe = (patientName ?? 'record').trim().replaceAll(
      RegExp(r'[^A-Za-z0-9\u0600-\u06FF]+'),
      '-',
    );
    final from = range.start.toIso8601String().split('T').first;
    final to = range.end.toIso8601String().split('T').first;
    return 'tafaqod-$safe-$from-$to.pdf';
  }

  RecordPdfSection _summarySection(
    List<DoseOccurrence> doses,
    List<MeasurementReading> readings,
    List<MeasurementOccurrence> tasks,
    List<CareAppointment> appointments,
  ) {
    final resolvedDoses = doses.where((item) => item.record != null).length;
    final missedDoses = doses
        .where(
          (item) =>
              item.record == null && item.timingState == DoseTimingState.missed,
        )
        .length;
    final missedMeasurements = tasks
        .where((item) => item.status == MeasurementStatus.missed)
        .length;
    return RecordPdfSection(
      title: context.tr('record_export.summary'),
      rows: [
        RecordPdfRow(
          label: context.tr('record_export.current_medications'),
          value:
              '${widget.plans.where((item) => !item.isPreviousOn(_today)).length}',
          ltr: true,
        ),
        RecordPdfRow(
          label: context.tr('record_export.recorded_doses'),
          value: '$resolvedDoses',
          ltr: true,
        ),
        RecordPdfRow(
          label: context.tr('record_export.missed_tasks'),
          value: '${missedDoses + missedMeasurements}',
          ltr: true,
        ),
        RecordPdfRow(
          label: context.tr('record_export.measurement_count'),
          value: '${readings.where((item) => item.outcome == 'read').length}',
          ltr: true,
        ),
        RecordPdfRow(
          label: context.tr('record_export.outside_count'),
          value:
              '${readings.where((item) => item.outsideTarget == true).length}',
          ltr: true,
        ),
        RecordPdfRow(
          label: context.tr('record_export.appointment_count'),
          value: '${appointments.length}',
          ltr: true,
        ),
      ],
    );
  }

  Future<bool?> _confirmSummary(
    List<DoseOccurrence> doses,
    List<MeasurementReading> readings,
    List<MeasurementOccurrence> tasks,
    List<CareAppointment> appointments,
  ) {
    final missed =
        doses
            .where(
              (item) =>
                  item.record == null &&
                  item.timingState == DoseTimingState.missed,
            )
            .length +
        tasks.where((item) => item.status == MeasurementStatus.missed).length;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('record_export.preview_title')),
        content: Text(
          context.tr(
            'record_export.preview_text',
            args: [
              '${widget.plans.where((item) => !item.isPreviousOn(_today)).length}',
              '${doses.where((item) => item.record != null).length}',
              '$missed',
              '${readings.where((item) => item.outcome == 'read').length}',
              '${appointments.length}',
            ],
          ),
        ),
        actions: [
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

  RecordPdfSection _doseSection(List<DoseOccurrence> doses) {
    final visible = doses.where(
      (item) =>
          item.record != null || item.timingState == DoseTimingState.missed,
    );
    final yesterday = DateTime(_today.year, _today.month, _today.day - 1);
    return RecordPdfSection(
      title: context.tr('record_export.dose_log'),
      empty: visible.isEmpty ? context.tr('medications.no_dose_history') : null,
      items: [
        for (final dose in visible)
          RecordPdfItem(
            title: dose.name,
            badge: dose.record?.outcome == DoseOutcome.taken
                ? context.tr('today_dashboard.status.taken')
                : dose.record?.outcome == DoseOutcome.skipped
                ? context.tr('today_dashboard.status.skipped')
                : context.tr(
                    DateUtils.dateOnly(dose.scheduledOn).isBefore(yesterday)
                        ? 'medications.timing.missed'
                        : 'medications.timing.unrecorded',
                  ),
            badgeMuted: dose.record?.outcome != DoseOutcome.taken,
            detail: [
              RecordPdfRow(
                value:
                    '${formatBirthDate(context, dose.scheduledOn)} · '
                    '${clockText(dose.time)}',
              ),
            ],
            fields: [
              if (dose.record case final record?
                  when record.outcome == DoseOutcome.skipped &&
                      record.skipReasonCode != null)
                RecordPdfRow(
                  label: context.tr('record_export.skip_reason'),
                  value: doseSkipReasonText(context, record),
                ),
              if (dose.record?.recordedByName case final name?)
                RecordPdfRow(
                  label: context.tr('record_export.recorded_by'),
                  value: name,
                ),
            ],
          ),
      ],
    );
  }

  RecordPdfSection _missedMeasurementSection(
    List<MeasurementOccurrence> tasks,
  ) {
    final missed = tasks.where(
      (item) => item.status == MeasurementStatus.missed,
    );
    final yesterday = DateTime(_today.year, _today.month, _today.day - 1);
    return RecordPdfSection(
      title: context.tr('record_export.unrecorded_measurements'),
      empty: missed.isEmpty ? context.tr('measurements.no_readings') : null,
      items: [
        for (final task in missed)
          RecordPdfItem(
            title: context.tr(
              task.kind == MeasurementKind.glucose
                  ? 'measurements.glucose'
                  : 'measurements.bp',
            ),
            badge: context.tr(
              DateUtils.dateOnly(task.scheduledOn).isBefore(yesterday)
                  ? 'measurements.missed'
                  : 'measurements.unrecorded',
            ),
            badgeMuted: true,
            detail: [
              RecordPdfRow(
                value:
                    '${formatBirthDate(context, task.scheduledOn)} · '
                    '${clockText(task.time)}',
              ),
              if (task.measurementState != null)
                RecordPdfRow(
                  value: context.tr(
                    'measurements.condition.${task.measurementState}',
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// The patient's data as label-value lines. The blood type and the phone
  /// numbers are set left to right on their own, so the page never reverses
  /// them.
  RecordPdfSection _medicalSection(MedicalFile file) => RecordPdfSection(
    title: context.tr('record_export.medical_file'),
    rows: <RecordPdfRow>[
      RecordPdfRow(
        label: context.tr('circles.name'),
        value: file.patient.fullName,
      ),
      RecordPdfRow(
        label: context.tr('circles.birth_date'),
        value: formatBirthDate(context, file.patient.birthDate),
      ),
      RecordPdfRow(label: context.tr('circles.city'), value: file.patient.city),
      RecordPdfRow(
        label: context.tr('circles.blood_type'),
        value: MedicalTexts.bloodType(context, file.profile.bloodType),
        ltr: file.profile.bloodType != null,
      ),
      RecordPdfRow(
        label: context.tr('circles.allergies_title'),
        value: MedicalTexts.allergies(context, file.profile.allergies),
      ),
      RecordPdfRow(
        label: context.tr('circles.conditions'),
        value: MedicalTexts.conditions(context, file.profile.conditions),
      ),
      if (_includeContacts)
        for (final contact in file.contacts)
          RecordPdfRow(
            label: MedicalTexts.relation(context, contact),
            value: contact.name,
            extra: MedicalTexts.phone(contact),
          ),
    ],
  );

  /// One block per medicine: its name and whether it is current, the
  /// strength (left to right) and the form, and one line per dose time.
  RecordPdfSection _medicationSection(List<MedicationPlan> plans) {
    final today = PatientClockScope.of(context).today();
    return RecordPdfSection(
      title: context.tr('record_export.medications'),
      empty: plans.isEmpty ? context.tr('medications.no_records') : null,
      items: <RecordPdfItem>[
        for (final plan in plans)
          RecordPdfItem(
            title: plan.version.name,
            badge: context.tr(
              plan.isPreviousOn(today)
                  ? 'record_export.previous'
                  : 'record_export.current',
            ),
            badgeMuted: plan.isPreviousOn(today),
            detail: <RecordPdfRow>[
              RecordPdfRow(
                value:
                    '${formatMedicationNumber(plan.version.strengthValue)} '
                    '${plan.version.strengthUnit.apiValue}',
                ltr: true,
              ),
              RecordPdfRow(
                value: context.tr(
                  'medications.form.${plan.version.dosageForm.name}',
                ),
              ),
            ],
            rows: <RecordPdfRow>[
              for (final schedule in plan.version.schedules)
                RecordPdfRow(
                  label: schedule.time,
                  value:
                      '${formatMedicationNumber(schedule.doseValue)} '
                      '${context.tr('medications.unit.${schedule.doseUnit.name}')}',
                ),
            ],
          ),
      ],
    );
  }

  RecordPdfSection _measurementSection(
    List<MeasurementReading> readings,
  ) => RecordPdfSection(
    title: context.tr('record_export.measurements'),
    empty: readings.isEmpty ? context.tr('measurements.no_readings') : null,
    items: [
      for (final reading in readings)
        RecordPdfItem(
          title: context.tr(
            reading.kind == MeasurementKind.bp
                ? 'measurements.bp'
                : 'measurements.glucose',
          ),
          badge: context.tr(
            reading.outcome == 'skipped'
                ? 'measurements.skipped'
                : reading.outsideTarget == true
                ? 'measurements.outside_target'
                : reading.outsideTarget == null
                ? 'measurements.without_target'
                : 'measurements.read',
          ),
          badgeMuted: reading.outcome == 'skipped',
          detail: [RecordPdfRow(value: _readingDate(reading))],
          fields: [
            if (reading.outcome != 'skipped')
              RecordPdfRow(
                label: context.tr('measurements.value'),
                value: reading.valueText,
                unit: context.tr(
                  reading.kind == MeasurementKind.bp
                      ? 'measurements.bp_unit'
                      : 'measurements.glucose_unit',
                ),
                ltr: true,
              ),
            if (reading.planVersionId == null && reading.outcome != 'skipped')
              RecordPdfRow(
                label: context.tr('measurements.target'),
                value: reading.outsideTarget == null
                    ? context.tr('measurements.without_target')
                    : reading.kind == MeasurementKind.glucose
                    ? '${reading.glucoseLow}–${reading.glucoseHigh}'
                    : '${reading.systolicLimit}/${reading.diastolicLimit}',
                ltr: reading.outsideTarget != null,
              ),
            if (reading.outcome == 'read' && reading.conditions.isNotEmpty)
              RecordPdfRow(
                label: context.tr('measurements.condition_optional'),
                value: readingConditionsText(context, reading),
              ),
            if (reading.outcome == 'skipped' && reading.skipReasonCode != null)
              RecordPdfRow(
                label: context.tr('record_export.skip_reason'),
                value: measurementSkipReasonText(context, reading),
              ),
            if (reading.note?.isNotEmpty == true)
              RecordPdfRow(
                label: context.tr('measurements.note'),
                value: reading.note!,
              ),
          ],
        ),
    ],
  );

  String _readingDate(MeasurementReading reading) {
    final date = reading.measuredAt?.toLocal() ?? reading.scheduledOn;
    if (date == null) return '';
    final day = date.toIso8601String().split('T').first;
    if (reading.outcome == 'skipped') return day;
    return '$day ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  RecordPdfSection _appointmentSection(
    List<CareAppointment> appointments,
    Map<String, VisitPaper> visits,
  ) => RecordPdfSection(
    title: context.tr('record_export.appointments'),
    empty: appointments.isEmpty ? context.tr('appointments.no_records') : null,
    items: [
      for (final item in appointments)
        RecordPdfItem(
          title: appointmentTitle(context, item),
          badge: context.tr('appointments.status.${item.status.name}'),
          badgeMuted: item.status != AppointmentStatus.completed,
          detail: [
            RecordPdfRow(value: appointmentDate(context, item.scheduledOn)),
            RecordPdfRow(value: clockText(item.time)),
            RecordPdfRow(value: appointmentKindTitle(context, item)),
          ],
          fields: [
            RecordPdfRow(
              label: context.tr('appointments.place'),
              value: item.kind == AppointmentKind.remote
                  ? context.tr('appointments.${item.remoteMethod}')
                  : item.place ?? '',
            ),
            RecordPdfRow(
              label: context.tr('appointments.companion'),
              value: appointmentCompanionNames(context, item),
            ),
            if (visits[item.id] case final visit?) ...[
              if (visit.summary?.isNotEmpty == true)
                RecordPdfRow(
                  label: context.tr('appointments.visit_summary'),
                  value: visit.summary!,
                ),
              if (visit.recommendations?.isNotEmpty == true)
                RecordPdfRow(
                  label: context.tr('appointments.visit_recommendations'),
                  value: visit.recommendations!,
                ),
              if (visit.followUp?.isNotEmpty == true)
                RecordPdfRow(
                  label: context.tr('appointments.visit_follow_up'),
                  value: visit.followUp!,
                ),
              if (visit.hasAudio)
                RecordPdfRow(value: context.tr('record_export.audio_separate')),
            ],
          ],
        ),
    ],
  );

  Future<void> _pickCustomRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: _today,
      initialDateRange: _customRange ?? _selectedRange,
    );
    if (selected != null && mounted) {
      setState(() {
        _customRange = selected;
        _range = _ExportRange.custom;
      });
    }
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
              SegmentedButton<_ExportMode>(
                segments: [
                  ButtonSegment(
                    value: _ExportMode.summary,
                    label: Text(context.tr('record_export.mode.summary')),
                  ),
                  ButtonSegment(
                    value: _ExportMode.detailed,
                    label: Text(context.tr('record_export.mode.detailed')),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.first),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<_ExportRange>(
                initialValue: _range,
                decoration: InputDecoration(
                  labelText: context.tr('record_export.period'),
                ),
                items: [
                  for (final value in _ExportRange.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        value == _ExportRange.custom && _customRange != null
                            ? _rangeText(_customRange!)
                            : context.tr('record_export.range.${value.name}'),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  if (value == _ExportRange.custom) {
                    _pickCustomRange();
                  } else {
                    setState(() => _range = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                title: Text(context.tr('record_export.medical_file')),
                value: _medical && state.medicalFile != null,
                onChanged: state.medicalFile == null
                    ? null
                    : (value) => setState(() => _medical = value ?? false),
              ),
              CheckboxListTile(
                title: Text(context.tr('record_export.medications')),
                value: _medications,
                onChanged: (value) =>
                    setState(() => _medications = value ?? false),
              ),
              if (_medical && state.medicalFile != null)
                SwitchListTile(
                  title: Text(context.tr('record_export.include_contacts')),
                  value: _includeContacts,
                  onChanged: (value) =>
                      setState(() => _includeContacts = value),
                ),
              CheckboxListTile(
                title: Text(context.tr('record_export.measurements')),
                value: _measurements,
                onChanged: (value) =>
                    setState(() => _measurements = value ?? false),
              ),
              CheckboxListTile(
                title: Text(context.tr('record_export.appointments')),
                value: _appointments,
                onChanged: (value) =>
                    setState(() => _appointments = value ?? false),
              ),
              if (_errorKey != null || state.errorKey != null) ...[
                const SizedBox(height: AppSpacing.sm),
                // Lined up with the text of the rows above.
                InsetText(
                  context.tr(_errorKey ?? state.errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed:
                    state.status == RecordExportStatus.ready &&
                        !state.sharing &&
                        ((_medical && state.medicalFile != null) ||
                            _medications ||
                            _measurements ||
                            _appointments)
                    ? () => _share(state)
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
