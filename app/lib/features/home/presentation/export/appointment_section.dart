import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The appointments of the period, oldest first, each with its status and,
/// when it was completed, what the visit paper says.
RecordPdfSection appointmentSection(
  BuildContext context,
  RecordExportData data,
) {
  final List<CareAppointment> sorted = <CareAppointment>[...data.appointments]
    ..sort((a, b) {
      final int byDay = a.scheduledOn.compareTo(b.scheduledOn);
      return byDay != 0 ? byDay : a.time.compareTo(b.time);
    });
  return RecordPdfSection(
    title: context.tr('record_export.appointments'),
    empty: sorted.isEmpty ? context.tr('appointments.no_records') : null,
    items: <RecordPdfItem>[
      for (final CareAppointment item in sorted)
        _item(context, item, data.visits[item.id]),
    ],
  );
}

RecordPdfItem _item(
  BuildContext context,
  CareAppointment item,
  VisitPaper? visit,
) => RecordPdfItem(
  title: appointmentTitle(context, item),
  badge: context.tr('appointments.status.${item.status.name}'),
  badgeMuted: item.status != AppointmentStatus.completed,
  detail: <RecordPdfRow>[
    RecordPdfRow(value: appointmentDate(context, item.scheduledOn)),
    RecordPdfRow(value: clockText(item.time)),
    if (appointmentClinic(item) case final String clinic)
      RecordPdfRow(value: clinic),
  ],
  fields: <RecordPdfRow>[
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
    ..._visitRows(context, visit),
  ],
);

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
