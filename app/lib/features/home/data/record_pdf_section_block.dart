import 'package:app/features/home/data/record_pdf_item_block.dart';
import 'package:app/features/home/data/record_pdf_model.dart';
import 'package:app/features/home/data/record_pdf_rows.dart';
import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/data/record_pdf_table_block.dart';
import 'package:pdf/widgets.dart' as pw;

/// A section: its heading with a rule under it, then whatever it holds.
List<pw.Widget> pdfSection(RecordPdfSection section) {
  final String? empty = section.empty;
  return <pw.Widget>[
    pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: RecordPdfStyle.ink, width: 1.2),
        ),
      ),
      child: pw.Text(
        RecordPdfStyle.plain(section.title),
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    ),
    if (section.rows.isNotEmpty) pdfBox(section.rows),
    for (final RecordPdfTable table in section.tables) pdfTable(table),
    for (final RecordPdfItem item in section.items) pdfItem(item),
    if (empty != null)
      pw.Text(
        RecordPdfStyle.plain(empty),
        style: pw.TextStyle(color: RecordPdfStyle.slate),
      ),
    pw.SizedBox(height: 22),
  ];
}
