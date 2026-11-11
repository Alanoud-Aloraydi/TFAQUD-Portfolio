import 'package:pdf/pdf.dart';

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
