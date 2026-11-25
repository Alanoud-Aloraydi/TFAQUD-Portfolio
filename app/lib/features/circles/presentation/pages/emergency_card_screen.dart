import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_content.dart';
import 'package:app/features/circles/presentation/widgets/page_frame_padding.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// The emergency card of a circle (CIRCLE-07), as in the handoff: one white
/// card with an ink edge that a stranger can read in a hurry (a paramedic, a
/// school, a neighbour). The red badge, the name and age, the blood type in
/// a dark box, the allergy in a red box, the chronic conditions, the current
/// medicines and the people to call. Under it the ambulance button and why
/// the card is separate from the medical file.
///
/// «عربي / English» switches the card's language; medicine names and typed
/// text stay as written. «تصدير» shares the card as a PDF. The card is
/// read-only. Needs an [EmergencyCardCubit] and a [MedicationsCubit] above
/// it.
class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key, this.closeTo = Routes.circle});

  /// Where «رجوع» goes when there is no page under the card to return to
  /// (an address opened directly): the circle tab in the detailed mode,
  /// the simplified home in the simplified mode.
  final String closeTo;

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen>
    with EmergencyCardSharing<EmergencyCardScreen> {
  bool _english = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmergencyCardCubit, EmergencyCardState>(
          listenWhen: (EmergencyCardState before, EmergencyCardState after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (BuildContext context, EmergencyCardState state) =>
              context.go(Routes.auth),
          builder: (BuildContext context, EmergencyCardState state) =>
              EmergencyCardPage(
                state: state,
                closeTo: widget.closeTo,
                cardKey: cardKey,
                english: _english,
                onLanguage: (bool english) =>
                    setState(() => _english = english),
                onExport: exporting ? null : export,
              ),
        ),
      ),
    );
  }
}

/// What the emergency card page keeps to share the card as a PDF: where the
/// picture is taken from, whether a PDF is being made, and the tap that
/// makes and shares it, with a toast when that fails.
mixin EmergencyCardSharing<T extends StatefulWidget> on State<T> {
  /// The picture of the card for the PDF is taken from here.
  final GlobalKey cardKey = GlobalKey();
  bool exporting = false;

  Future<void> export() async {
    if (exporting) return;
    setState(() => exporting = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failed = context.tr('record_export.failed');
    final bool shared = await shareEmergencyCardSafely(
      boundary: cardKey,
      title: context.tr('circles.card_title'),
    );
    if (!mounted) return;
    setState(() => exporting = false);
    if (!shared) AppToast.showText(messenger, failed, kind: ToastKind.error);
  }
}

/// The emergency card page under its safe area: the top row, the title, and
/// the card or what stands in for it. Loading, error and content fade into
/// each other.
class EmergencyCardPage extends StatelessWidget {
  const EmergencyCardPage({
    super.key,
    required this.state,
    required this.closeTo,
    required this.cardKey,
    required this.english,
    required this.onLanguage,
    required this.onExport,
  });

  final EmergencyCardState state;
  final String closeTo;
  final GlobalKey cardKey;
  final bool english;
  final ValueChanged<bool> onLanguage;

  /// Null while a PDF is being made.
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: pageFramePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EmergencyCardTopRow(
            closeTo: closeTo,
            canExport: state.status == EmergencyCardStatus.ready,
            onExport: onExport,
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              context.tr('circles.card_title'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ContentSwitcher(
              stateKey: state.status,
              child: EmergencyCardContent(
                state: state,
                cardKey: cardKey,
                english: english,
                onLanguage: onLanguage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
