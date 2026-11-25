import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
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

/// [shareEmergencyCardPdf], with a failure to draw or to share reported as
/// false, so the page has one answer to show.
Future<bool> shareEmergencyCardSafely({
  required GlobalKey boundary,
  required String title,
}) async {
  try {
    return await shareEmergencyCardPdf(boundary: boundary, title: title);
  } on Exception {
    return false;
  }
}

/// «رجوع» and, once the card is on screen, «تصدير».
class EmergencyCardTopRow extends StatelessWidget {
  const EmergencyCardTopRow({
    super.key,
    required this.closeTo,
    required this.canExport,
    required this.onExport,
  });

  /// Where «رجوع» goes when there is no page under the card.
  final String closeTo;
  final bool canExport;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        BackLink(
          onPressed: context.canPop()
              ? () => context.pop()
              : () => context.go(closeTo),
        ),
        const Spacer(),
        if (canExport)
          TextButton.icon(
            onPressed: onExport,
            icon: const Icon(NoticeIcons.export, size: AppSizes.iconSmall),
            label: Text(context.tr('emergency_card.export')),
          ),
      ],
    );
  }
}
