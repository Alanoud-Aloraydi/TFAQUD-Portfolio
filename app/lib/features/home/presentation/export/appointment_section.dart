import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/appointment_row.dart';
import 'package:app/features/home/presentation/export/visit_paper_rows.dart';
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
            for (final CareAppointment item in sorted)
              appointmentRow(context, item),
          ],
        ),
    ],
    items: <RecordPdfItem>[
      for (final CareAppointment item in sorted)
        if (visitPaperRows(context, data.visits[item.id]) case final rows
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
