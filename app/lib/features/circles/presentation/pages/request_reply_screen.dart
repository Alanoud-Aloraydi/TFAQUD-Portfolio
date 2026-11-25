import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:app/features/circles/presentation/pages/request_reply_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page of a request addressed to the signed-in person (CREAT-06): who
/// asks, the name of the circle, the mode proposed for the patient's app, and
/// the two answers. Agreeing leads to the basic data; declining goes back.
/// Needs a [RequestReplyCubit] above it.
class RequestReplyScreen extends StatelessWidget {
  const RequestReplyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestReplyCubit cubit = context.read<RequestReplyCubit>();
    final ReceivedCircleRequest request = cubit.request;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocConsumer<RequestReplyCubit, RequestReplyState>(
            listenWhen: (RequestReplyState before, RequestReplyState after) =>
                (after.sessionEnded && !before.sessionEnded) ||
                (after.outcome != before.outcome &&
                    after.outcome != ReplyOutcome.none),
            listener: (BuildContext context, RequestReplyState state) =>
                onRequestReplyState(context, state, request),
            builder: (BuildContext context, RequestReplyState state) {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: requestReplyBody(context, state, request),
                      ),
                    ),
                  ),
                  ...requestReplyActions(context, state, cubit),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

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
