import 'package:app/features/home/domain/entities/record_pdf_cell.dart';

/// A table with a [title], its column [headers] and [rows]. [flex] sizes the
/// columns against each other.
class RecordPdfTable {
  const RecordPdfTable({
    required this.title,
    required this.headers,
    required this.flex,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<int> flex;
  final List<List<RecordPdfCell>> rows;
}
