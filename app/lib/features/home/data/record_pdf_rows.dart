import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/widgets.dart' as pw;

/// A value on its own: left to right when it is a number or a code, and
/// still placed at the start (the right) of its cell.
pw.Widget pdfValue(String value, {required bool ltr, pw.TextStyle? style}) {
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      RecordPdfStyle.plain(value),
      textDirection: ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      style: style,
    ),
  );
}

/// One label-value line.
pw.Widget pdfRow(RecordPdfRow row) {
  final String? label = row.label;
  final String? extra = row.extra;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      if (label != null)
        pw.SizedBox(
          width: RecordPdfStyle.labelWidth,
          child: pw.Text(
            RecordPdfStyle.plain(label),
            style: pw.TextStyle(fontSize: 10, color: RecordPdfStyle.slate),
          ),
        ),
      pw.Expanded(child: pdfValue(row.value, ltr: row.ltr)),
      if (extra != null)
        pw.Text(
          RecordPdfStyle.plain(extra),
          textDirection: pw.TextDirection.ltr,
          style: pw.TextStyle(fontSize: 10.5, color: RecordPdfStyle.slate),
        ),
    ],
  );
}

/// Label-value lines in a light box, with a thin line between them.
pw.Widget pdfBox(List<RecordPdfRow> rows) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14),
    decoration: pw.BoxDecoration(
      color: RecordPdfStyle.panel,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: <pw.Widget>[
        for (int i = 0; i < rows.length; i++)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: i == 0
                ? null
                : pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: RecordPdfStyle.line),
                    ),
                  ),
            child: pdfRow(rows[i]),
          ),
      ],
    ),
  );
}
