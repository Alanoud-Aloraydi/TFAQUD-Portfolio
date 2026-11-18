import 'package:app/features/home/domain/entities/record_pdf_row.dart';

/// A block in a section, such as one medicine: its [title], a short
/// [detail] made of pieces (each piece is one run, so «500 mg» and «أقراص»
/// keep their own direction), a [badge] (حالي / سابق) and its [rows] (the
/// dose times).
class RecordPdfItem {
  const RecordPdfItem({
    required this.title,
    this.detail = const <RecordPdfRow>[],
    this.badge,
    this.badgeMuted = false,
    this.rows = const <RecordPdfRow>[],
    this.fields = const <RecordPdfRow>[],
  });

  final String title;
  final List<RecordPdfRow> detail;
  final String? badge;

  /// A grey badge (a medicine that ended) instead of the green one.
  final bool badgeMuted;
  final List<RecordPdfRow> rows;
  final List<RecordPdfRow> fields;
}
