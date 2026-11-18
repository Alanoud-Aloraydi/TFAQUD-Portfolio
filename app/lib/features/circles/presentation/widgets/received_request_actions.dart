import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the page of a received request at [route], then reads the inbox
/// again for what that page changed.
Future<void> openReceivedRequest(
  BuildContext context,
  InboxCubit cubit,
  String route,
  ReceivedCircleRequest request,
) async {
  await context.push<void>(route, extra: request);
  if (!cubit.isClosed) cubit.load();
}

/// Asks the patient to confirm, then cancels the request they had accepted.
Future<void> confirmCancelRequest(
  BuildContext context,
  InboxCubit cubit,
  ReceivedCircleRequest request,
) async {
  final bool? yes = await showAppAlert<bool>(
    context,
    title: context.tr('circles.cancel_confirm_title'),
    message: context.tr('circles.cancel_confirm_body_patient'),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(
        label: context.tr('circles.cancel_confirm_no'),
        value: false,
      ),
      AppAlertAction<bool>(
        label: context.tr('circles.cancel_confirm_yes'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (yes != true) return;
  final bool canceled = await cubit.cancelRequest(request.id);
  if (canceled && context.mounted) {
    AppToast.show(context, 'toast.request_canceled');
  }
}
