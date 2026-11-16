import 'dart:async';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A tapped reminder shows «اليوم» of its circle.
void openToday(BuildContext context, String? circleId) {
  if (!context.mounted) return;
  if (circleId != null) {
    unawaited(context.read<HomeCubit>().selectCircle(circleId));
  }
  context.go(Routes.today);
}

/// A tapped push about an invitation or a request: its page.
void openInbox(BuildContext context) {
  if (!context.mounted) return;
  unawaited(context.push(Routes.notifications));
}

/// Says when a reminder put off from its notification comes again.
void showSnoozed(BuildContext context) {
  if (!context.mounted) return;
  AppToast.showText(
    ScaffoldMessenger.of(context),
    context.tr(
      'reminders.snoozed',
      args: <String>[afterDuration(context, notificationSnooze.inMinutes)],
    ),
  );
}

/// Opens the notifications and counts again when the person comes back,
/// because an answer there changes what is left.
Future<void> openNotifications(BuildContext context) async {
  final InboxCubit inbox = context.read<InboxCubit>();
  await context.push<void>(Routes.notifications);
  if (!inbox.isClosed) unawaited(inbox.load());
}
