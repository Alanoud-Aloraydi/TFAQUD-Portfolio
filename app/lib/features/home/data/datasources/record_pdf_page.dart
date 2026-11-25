import 'package:app/features/home/data/datasources/record_pdf_rows.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/pdf.dart';
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

/// Colours and sizes shared by every block of the exported record.
abstract class RecordPdfStyle {
  RecordPdfStyle._();

  static final PdfColor ink = PdfColor.fromHex('#202734');
  static final PdfColor slate = PdfColor.fromHex('#4E5A75');
  static final PdfColor line = PdfColor.fromHex('#DFE2EA');
  static final PdfColor panel = PdfColor.fromHex('#F6F7F9');
  // The app's leaf tint (AppColors.leafTint).
  static final PdfColor leaf = PdfColor.fromHex('#E3F3EA');
  static final PdfColor leafInk = PdfColor.fromHex('#3D6B1C');
  static final PdfColor warn = PdfColor.fromHex('#B54708');

  static const double labelWidth = 110;

  /// The column of a dose time, wide enough for «22:00» and a little air.
  static const double timeWidth = 40;

  /// The direction marks and isolates (U+200E, U+200F, U+202A to U+202E,
  /// U+2066 to U+2069). The PDF font draws them as boxes.
  static const String _markRanges = '\u200E\u200F\u202A-\u202E\u2066-\u2069';
  static final RegExp _marks = RegExp('[$_markRanges]');

  /// [text] without the direction marks the PDF font cannot draw.
  static String plain(String text) => text.replaceAll(_marks, '').trim();
}
