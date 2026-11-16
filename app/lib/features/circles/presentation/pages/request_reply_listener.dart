import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reacts to the answer being sent: leaves when the session ended, goes on
/// to the basic data after agreeing, and goes back after declining.
void onRequestReplyState(
  BuildContext context,
  RequestReplyState state,
  ReceivedCircleRequest request,
) {
  if (state.sessionEnded) {
    context.go(Routes.auth);
  } else if (state.outcome == ReplyOutcome.accepted) {
    AppToast.show(context, 'toast.request_accepted');
    context.pushReplacement(Routes.completeRequest, extra: request);
  } else {
    AppToast.show(context, 'toast.request_declined');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.notifications);
    }
  }
}
