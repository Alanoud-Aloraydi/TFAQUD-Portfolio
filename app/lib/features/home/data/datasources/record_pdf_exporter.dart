import 'package:app/features/home/data/datasources/record_pdf_page.dart';
import 'package:app/features/home/data/datasources/record_pdf_rows.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/repositories/record_exporter.dart';
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

/// One medicine or appointment: the name and its badge, a short detail, one
/// line per time, and a box of fields.
pw.Widget pdfItem(RecordPdfItem item) {
  final String? badge = item.badge;
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: RecordPdfStyle.line),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Text(
                RecordPdfStyle.plain(item.title),
                style: pw.TextStyle(
                  fontSize: 12.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (badge != null) pdfBadge(badge, muted: item.badgeMuted),
          ],
        ),
        if (item.detail.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 2),
          pdfDetail(item.detail),
        ],
        if (item.rows.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 8),
          for (final RecordPdfRow row in item.rows) pdfTimeRow(row),
        ],
        if (item.fields.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 8),
          pdfBox(item.fields),
        ],
      ],
    ),
  );
}

/// A pill with a short word in it: «حالي», «تم أخذها».
pw.Widget pdfBadge(String text, {required bool muted}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: pw.BoxDecoration(
      color: muted ? RecordPdfStyle.panel : RecordPdfStyle.leaf,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Text(
      RecordPdfStyle.plain(text),
      style: pw.TextStyle(
        fontSize: 9,
        color: muted ? RecordPdfStyle.slate : RecordPdfStyle.leafInk,
      ),
    ),
  );
}

/// The short grey line under a title; each piece keeps its own direction.
pw.Widget pdfDetail(List<RecordPdfRow> detail) {
  return pw.Wrap(
    spacing: 6,
    children: <pw.Widget>[
      for (int i = 0; i < detail.length; i++) ...<pw.Widget>[
        if (i > 0)
          pw.Text('|', style: pw.TextStyle(color: RecordPdfStyle.slate)),
        pw.Text(
          RecordPdfStyle.plain(detail[i].value),
          textDirection: detail[i].ltr
              ? pw.TextDirection.ltr
              : pw.TextDirection.rtl,
          style: pw.TextStyle(fontSize: 10.5, color: RecordPdfStyle.slate),
        ),
      ],
    ],
  );
}

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
