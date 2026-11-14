import 'package:app/features/home/data/record_pdf_rows.dart';
import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/widgets.dart' as pw;

/// The top of the first page: app name, title and the header lines.
pw.Widget pdfTitle(RecordPdfDocument document) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(
        RecordPdfStyle.plain(document.appName),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: RecordPdfStyle.leafInk,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        RecordPdfStyle.plain(document.title),
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pdfBox(document.header),
    ],
  );
}

/// The small title on every page after the first.
pw.Widget pdfRunningHeader(pw.Context context, RecordPdfDocument document) {
  if (context.pageNumber == 1) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Text(
      RecordPdfStyle.plain(document.title),
      style: pw.TextStyle(fontSize: 9, color: RecordPdfStyle.slate),
    ),
  );
}

/// The app name and the page number at the foot of every page.
pw.Widget pdfFooter(
  pw.Context context,
  RecordPdfDocument document,
  String Function(int page, int pages) pageLabel,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: RecordPdfStyle.line)),
    ),
    child: pw.Row(
      children: <pw.Widget>[
        pw.Text(
          RecordPdfStyle.plain(document.appName),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: RecordPdfStyle.slate,
          ),
        ),
        pw.Spacer(),
        pw.Text(
          RecordPdfStyle.plain(
            pageLabel(context.pageNumber, context.pagesCount),
          ),
          style: pw.TextStyle(fontSize: 9, color: RecordPdfStyle.slate),
        ),
      ],
    ),
  );
}
