import 'dart:async';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// What a switch does when the phone refused its permission before: iOS
/// asks only once, so the way back is the phone's Settings. A switch that
/// quietly leaves the app reads as broken, so [wordsKey] says where it is
/// going, and the app stays [AppMotion.settingsLead] *after* the word is
/// fully on screen, so it is read; then it leaves. When the Settings page
/// does not open, [failedKey] says so.
Future<void> leaveForSettings(
  BuildContext context,
  String wordsKey, {
  required String failedKey,
}) async {
  // Taken before the await: the app leaves for Settings in between.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String failed = context.tr(failedKey);
  final Completer<void> shown = Completer<void>();
  AppToast.showText(
    messenger,
    context.tr(wordsKey),
    onVisible: () {
      if (!shown.isCompleted) shown.complete();
    },
  );
  // A word that never shows (no room for it) does not keep the app here.
  await shown.future.timeout(AppMotion.settingsLead, onTimeout: () {});
  await Future<void>.delayed(AppMotion.settingsLead);
  if (!await openAppSettingsPage()) {
    AppToast.showText(messenger, failed, kind: ToastKind.error);
  }
}
