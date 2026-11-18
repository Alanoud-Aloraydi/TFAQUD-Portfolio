import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_export.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
