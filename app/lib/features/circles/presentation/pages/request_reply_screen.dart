import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:app/features/circles/presentation/pages/request_reply_actions.dart';
import 'package:app/features/circles/presentation/pages/request_reply_body.dart';
import 'package:app/features/circles/presentation/pages/request_reply_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
