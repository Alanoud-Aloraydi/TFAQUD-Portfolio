import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates the circle of the page's flow ([CreateCircleCubit.create], with
/// the chip text [presetName]). When it is created, the «الدائرة» tab opens
/// on it (the home screen selects the new circle), where the medical file
/// waits with its «!» until it is filled, and a short line says the circle
/// is ready. `go` replaces the whole stack, so back never returns to the
/// creation pages. A refusal or a missing answer stays on the page, which
/// shows it.
///
/// [CircleFlow.approved] may instead commit the account to simplified mode
/// right there; the person goes straight to the simplified home, with no
/// detailed circle to visit and no sign-out/in needed to see it.
Future<void> createCircleAndOpen(
  BuildContext context,
  CreateCircleCubit cubit, {
  String presetName = '',
}) async {
  // Read before the page leaves the screen.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String notice = context.tr('circles.created_notice');
  final bool created = await cubit.create(presetName: presetName);
  if (!created || !context.mounted) return;
  if (cubit.state.switchToSimplified) {
    context.go(Routes.simplifiedMode);
    return;
  }
  context.go(Routes.circle);
  messenger.showSnackBar(SnackBar(content: Text(notice)));
}
