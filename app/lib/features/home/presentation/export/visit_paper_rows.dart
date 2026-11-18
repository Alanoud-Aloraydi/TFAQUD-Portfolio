import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What the paper of an attended visit says, one line per answer, and a
/// note when it has a recording that is shared on its own.
List<RecordPdfRow> visitPaperRows(BuildContext context, VisitPaper? visit) {
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
