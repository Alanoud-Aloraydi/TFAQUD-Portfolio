import 'package:app/features/home/data/record_pdf_rows.dart';
import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/widgets.dart' as pw;

/// One time and what is taken at it, the time pushed to the start.
pw.Widget pdfTimeRow(RecordPdfRow row) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 3),
    child: pw.Row(
      children: <pw.Widget>[
        pw.Container(
          width: RecordPdfStyle.timeWidth,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            RecordPdfStyle.plain(row.label ?? ''),
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pdfValue(
            row.value,
            ltr: row.ltr,
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        ),
      ],
    ),
  );
}
