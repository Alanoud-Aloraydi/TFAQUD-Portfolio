import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:pdf/widgets.dart' as pw;

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
