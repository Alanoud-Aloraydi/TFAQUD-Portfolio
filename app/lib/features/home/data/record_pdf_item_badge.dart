import 'package:app/features/home/data/record_pdf_style.dart';
import 'package:pdf/widgets.dart' as pw;

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
