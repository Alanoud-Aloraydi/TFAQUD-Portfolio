import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/widgets.dart' as pw;

/// One cell: a number or a time is set left to right and pushed to the start
/// of its column; a value outside its target is bold and darker.
pw.Widget _cell(RecordPdfCell cell, int flex) {
  return pw.Expanded(
    flex: flex,
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          RecordPdfStyle.plain(cell.text),
          textDirection: cell.ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: cell.warn ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: cell.warn ? RecordPdfStyle.warn : RecordPdfStyle.ink,
          ),
        ),
      ),
    ),
  );
}

pw.Widget _header(RecordPdfTable table) {
  return pw.Container(
    color: RecordPdfStyle.panel,
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      children: <pw.Widget>[
        for (int i = 0; i < table.headers.length; i++)
          pw.Expanded(
            flex: table.flex[i],
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  RecordPdfStyle.plain(table.headers[i]),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: RecordPdfStyle.slate,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A titled table: a grey header line, then one line per row with a thin
/// rule between. Built from rows so the columns follow the page direction.
pw.Widget pdfTable(RecordPdfTable table) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          RecordPdfStyle.plain(table.title),
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ),
      _header(table),
      for (final List<RecordPdfCell> row in table.rows)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: RecordPdfStyle.line),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              for (int i = 0; i < row.length; i++) _cell(row[i], table.flex[i]),
            ],
          ),
        ),
      pw.SizedBox(height: 14),
    ],
  );
}
