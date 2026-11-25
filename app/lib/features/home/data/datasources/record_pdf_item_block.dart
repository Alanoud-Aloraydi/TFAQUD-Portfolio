import 'package:app/features/home/data/datasources/record_pdf_page.dart';
import 'package:app/features/home/data/datasources/record_pdf_rows.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/widgets.dart' as pw;

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
