import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The patient's answer to a request (CREAT-06). Agreeing is consent only: the
/// circle is created later, when the patient gives the basic data.
class RequestReplyCubit extends Cubit<RequestReplyState> {
  RequestReplyCubit(this._circles, this.request)
    : super(const RequestReplyState());

  final CirclesUseCase _circles;
  final ReceivedCircleRequest request;

  Future<void> accept() => _answer(accept: true);

  Future<void> decline() => _answer(accept: false);

  Future<void> _answer({required bool accept}) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearError: true));
    final result = await _circles.respondToRequest(request.id, accept: accept);
    if (isClosed) return;
    result.when(
      (CircleRequestStatus status) {
        // The server says what it saved. A request that is not answered the way
        // the patient asked (it was canceled meanwhile) never reaches here: the
        // server refuses it with an error.
        final bool agreed = status == CircleRequestStatus.accepted;
        emit(
          state.copyWith(
            sending: false,
            outcome: agreed ? ReplyOutcome.accepted : ReplyOutcome.declined,
          ),
        );
      },
      (Failure failure) => emit(
        state.copyWith(
          sending: false,
          errorKey: failure.messageKey,
          sessionEnded:
              failure is UnauthorizedFailure ||
              failure is SessionExpiredFailure,
        ),
      ),
    );
  }
}
