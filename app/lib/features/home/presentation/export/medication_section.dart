import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/home/data/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// One block per medicine, current ones first: its name and whether it is
/// current, the strength (left to right) and the form, and one line per dose
/// time.
RecordPdfSection medicationSection(
  BuildContext context,
  RecordExportData data,
) {
  final DateTime today = data.today;
  final List<MedicationPlan> plans = <MedicationPlan>[
    ...data.plans.where((p) => !p.isPreviousOn(today)),
    ...data.plans.where((p) => p.isPreviousOn(today)),
  ];
  return RecordPdfSection(
    title: context.tr('record_export.medications'),
    empty: plans.isEmpty ? context.tr('medications.no_records') : null,
    items: <RecordPdfItem>[
      for (final MedicationPlan plan in plans)
        _item(context, plan, previous: plan.isPreviousOn(today)),
    ],
  );
}

RecordPdfItem _item(
  BuildContext context,
  MedicationPlan plan, {
  required bool previous,
}) => RecordPdfItem(
  title: plan.version.name,
  badge: context.tr(
    previous ? 'record_export.previous' : 'record_export.current',
  ),
  badgeMuted: previous,
  detail: <RecordPdfRow>[
    RecordPdfRow(
      value:
          '${formatMedicationNumber(plan.version.strengthValue)} '
          '${plan.version.strengthUnit.apiValue}',
      ltr: true,
    ),
    RecordPdfRow(
      value: context.tr('medications.form.${plan.version.dosageForm.name}'),
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
);
