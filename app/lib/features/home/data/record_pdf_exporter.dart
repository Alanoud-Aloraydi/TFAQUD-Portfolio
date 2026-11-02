import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RecordPdfSection {
  const RecordPdfSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

/// Builds the selected care record locally and opens the iOS share sheet.
class RecordPdfExporter {
  Future<void> share({
    required String title,
    required List<RecordPdfSection> sections,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
    );
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: bold,
              fontSize: 20,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 20),
          for (final section in sections) ...[
            pw.Text(
              section.title,
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 8),
            for (final line in section.lines)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
              ),
            pw.SizedBox(height: 18),
          ],
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'tafaqod-care-record.pdf',
    );
  }
}
