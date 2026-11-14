import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

const List<int> _columnFlex = <int>[3, 2, 4, 4, 3, 3];

/// The appointments of the period as one table, oldest first, and under it
/// what the visit paper says for the ones that were attended — prose that
/// no column could hold.
RecordPdfSection appointmentSection(
  BuildContext context,
  RecordExportData data,
) {
  final List<CareAppointment> sorted = <CareAppointment>[...data.appointments]
    ..sort((CareAppointment a, CareAppointment b) {
      final int byDay = a.scheduledOn.compareTo(b.scheduledOn);
      return byDay != 0 ? byDay : a.time.compareTo(b.time);
    });
  return RecordPdfSection(
    title: context.tr('record_export.appointments'),
    empty: sorted.isEmpty ? context.tr('appointments.no_records') : null,
    tables: <RecordPdfTable>[
      if (sorted.isNotEmpty)
        RecordPdfTable(
          title: context.tr('record_export.appointments'),
          headers: <String>[
            context.tr('record_export.col_date'),
            context.tr('record_export.col_time'),
            context.tr('record_export.col_kind'),
            context.tr('appointments.place'),
            context.tr('appointments.companion'),
            context.tr('record_export.col_status'),
          ],
          flex: _columnFlex,
          rows: <List<RecordPdfCell>>[
            for (final CareAppointment item in sorted) _row(context, item),
          ],
        ),
    ],
    items: <RecordPdfItem>[
      for (final CareAppointment item in sorted)
        if (_visitRows(context, data.visits[item.id]) case final rows
            when rows.isNotEmpty)
          RecordPdfItem(
            title: appointmentTitle(context, item),
            detail: <RecordPdfRow>[
              RecordPdfRow(value: appointmentDate(context, item.scheduledOn)),
            ],
            fields: rows,
          ),
    ],
  );
}

List<RecordPdfCell> _row(BuildContext context, CareAppointment item) {
  final String place = item.kind == AppointmentKind.remote
      ? context.tr('appointments.${item.remoteMethod}')
      : item.place ?? '';
  final String? clinic = appointmentClinic(item);
  return <RecordPdfCell>[
    RecordPdfCell(appointmentDate(context, item.scheduledOn)),
    RecordPdfCell(clockText(item.time), ltr: true),
    RecordPdfCell(
      clinic == null
          ? appointmentTitle(context, item)
          : '${appointmentTitle(context, item)} · $clinic',
    ),
    RecordPdfCell(place),
    RecordPdfCell(appointmentCompanionNames(context, item)),
    RecordPdfCell(
      context.tr('appointments.status.${item.status.name}'),
      // An appointment nobody attended is the line a reader looks for.
      warn: item.status != AppointmentStatus.completed,
    ),
  ];
}

List<RecordPdfRow> _visitRows(BuildContext context, VisitPaper? visit) {
  if (visit == null) return const <RecordPdfRow>[];
  RecordPdfRow? line(String key, String? text) => text?.isNotEmpty == true
      ? RecordPdfRow(label: context.tr(key), value: text!)
      : null;
  return <RecordPdfRow>[
    ...<RecordPdfRow?>[
      line('appointments.visit_summary', visit.summary),
      line('appointments.visit_recommendations', visit.recommendations),
      line('appointments.visit_follow_up', visit.followUp),
    ].whereType<RecordPdfRow>(),
    if (visit.hasAudio)
      RecordPdfRow(value: context.tr('record_export.audio_separate')),
  ];
}
