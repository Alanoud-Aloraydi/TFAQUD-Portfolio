import 'package:app/features/home/data/record_pdf_page.dart';
import 'package:app/features/home/data/record_pdf_section_block.dart';
import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/services/record_exporter.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds the selected care record locally and opens the share sheet.
///
/// The page is set for reading on paper: a header with the patient, the
/// period and the time zone, one heading per section, and a footer with the
/// page number. The fonts have no glyph for the invisible direction marks the
/// app uses on screen, so they are taken out of every text; numbers keep
/// their order by being set left to right on their own.
class RecordPdfExporter implements RecordExporter {
  static const String _regularFont =
      'assets/fonts/IBMPlexSansArabic-Regular.ttf';
  static const String _boldFont = 'assets/fonts/IBMPlexSansArabic-Bold.ttf';

  @override
  Future<void> share({
    required RecordPdfDocument document,
    required String Function(int page, int pages) pageLabel,
    required String filename,
  }) async {
    final pw.Font regular = pw.Font.ttf(await rootBundle.load(_regularFont));
    final pw.Font bold = pw.Font.ttf(await rootBundle.load(_boldFont));
    final pw.Document pdf = pw.Document(
      title: RecordPdfStyle.plain(document.title),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 200,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle: pw.TextStyle(
            font: regular,
            fontSize: 11,
            lineSpacing: 3,
            color: RecordPdfStyle.ink,
          ),
        ),
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 32),
        header: (context) => pdfRunningHeader(context, document),
        footer: (context) => pdfFooter(context, document, pageLabel),
        build: (context) => <pw.Widget>[
          pdfTitle(document),
          pw.SizedBox(height: 20),
          for (final RecordPdfSection section in document.sections)
            ...pdfSection(section),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }
}
