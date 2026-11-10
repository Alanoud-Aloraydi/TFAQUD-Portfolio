import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shares the emergency card as a one-page PDF, the size of the card on the
/// screen: a picture of the card as drawn, so it looks the same on paper, in
/// the Files app or in a message. [boundary] is the key of the card's
/// RepaintBoundary. Returns false when the picture could not be made.
Future<bool> shareEmergencyCardPdf({
  required GlobalKey boundary,
  required String title,
}) async {
  final RenderObject? object = boundary.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return false;
  // Three pixels per point: sharp when printed.
  const double scale = 3;
  final ui.Image image = await object.toImage(pixelRatio: scale);
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) return false;
  const double margin = 12;
  final double width = image.width / scale;
  final double height = image.height / scale;
  final pw.Document document = pw.Document(title: title);
  final pw.MemoryImage picture = pw.MemoryImage(png.buffer.asUint8List());
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        width + margin * 2,
        height + margin * 2,
        marginAll: margin,
      ),
      build: (pw.Context context) => pw.Image(picture),
    ),
  );
  await Printing.sharePdf(
    bytes: await document.save(),
    filename: 'tafaqod-emergency-card.pdf',
  );
  return true;
}
