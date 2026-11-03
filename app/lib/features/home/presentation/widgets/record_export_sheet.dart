import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:app/features/home/data/record_pdf_exporter.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

Future<void> showRecordExportSheet(
  BuildContext context, {
  required String circleId,
  required List<MedicationPlan> plans,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider(
    create: (_) => RecordExportCubit(
      GetIt.I<CirclesUseCase>(),
      RecordPdfExporter(),
      circleId,
    )..load(),
    child: _RecordExportSheet(plans: List.unmodifiable(plans)),
  ),
);

class _RecordExportSheet extends StatefulWidget {
  const _RecordExportSheet({required this.plans});

  final List<MedicationPlan> plans;

  @override
  State<_RecordExportSheet> createState() => _RecordExportSheetState();
}

class _RecordExportSheetState extends State<_RecordExportSheet> {
  bool _medical = true;
  bool _medications = true;
  String? _errorKey;

  Future<void> _share(RecordExportState state) async {
    final file = state.medicalFile;
    if (_medical && file == null && !_medications) return;
    final sections = <RecordPdfSection>[
      if (_medical && file != null) _medicalSection(file),
      if (_medications) _medicationSection(widget.plans),
    ];
    final String exportedOn = context.tr(
      'record_export.exported_on',
      args: <String>[formatBirthDate(context, DateTime.now())],
    );
    // Read now: the footer is written after the page has awaited.
    final String pageTemplate = context.tr('record_export.page');
    final error = await context.read<RecordExportCubit>().share(
      title: context.tr('record_export.pdf_title'),
      subtitle: file == null
          ? exportedOn
          : '${file.patient.fullName} · $exportedOn',
      appName: context.tr('auth.app_name'),
      pageLabel: (int page, int pages) => pageTemplate
          .replaceFirst('{}', '$page')
          .replaceFirst('{}', '$pages'),
      sections: sections,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _errorKey = error);
    }
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
    final today = DateUtils.dateOnly(DateTime.now());
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
        builder: (context, state) => Column(
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
            CheckboxListTile(
              title: Text(context.tr('record_export.measurements')),
              value: false,
              onChanged: null,
            ),
            CheckboxListTile(
              title: Text(context.tr('record_export.appointments')),
              value: false,
              onChanged: null,
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
                      ((_medical && state.medicalFile != null) || _medications)
                  ? () => _share(state)
                  : null,
              child: Text(context.tr('record_export.share')),
            ),
          ],
        ),
      ),
    ),
  );
}
