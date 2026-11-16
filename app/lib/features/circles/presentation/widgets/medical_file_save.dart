import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Saves the medical file and, once it is saved, says so and leaves: for
/// [savedTo] when the page was opened on its way somewhere, else back to
/// the page under this one, else to the file itself.
Future<void> saveMedicalFile(
  BuildContext context,
  MedicalFileEditCubit cubit, {
  required String? savedTo,
  required String fileRoute,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final GoRouter router = GoRouter.of(context);
  final String saved = context.tr('circles.file_saved');
  if (!await cubit.save()) return;
  AppToast.showText(messenger, saved);
  if (savedTo != null) {
    router.go(savedTo);
  } else if (router.canPop()) {
    router.pop();
  } else {
    router.go(fileRoute);
  }
}
