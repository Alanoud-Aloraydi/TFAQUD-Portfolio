import 'package:app/features/home/domain/entities/record_pdf_item.dart';
import 'package:app/features/home/domain/entities/record_pdf_row.dart';
import 'package:app/features/home/domain/entities/record_pdf_table.dart';

/// A section of the record: a heading, then label-value [rows] in a box,
/// [tables], [items] as blocks, or the [empty] line.
class RecordPdfSection {
  const RecordPdfSection({
    required this.title,
    this.rows = const <RecordPdfRow>[],
    this.tables = const <RecordPdfTable>[],
    this.items = const <RecordPdfItem>[],
    this.empty,
  });

  final String title;
  final List<RecordPdfRow> rows;
  final List<RecordPdfTable> tables;
  final List<RecordPdfItem> items;
  final String? empty;
}
