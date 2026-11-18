import 'package:app/features/home/data/record_pdf_rows.dart';
import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/data/record_pdf_item_badge.dart';
import 'package:app/features/home/data/record_pdf_item_detail.dart';
import 'package:app/features/home/data/record_pdf_time_row.dart';
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
