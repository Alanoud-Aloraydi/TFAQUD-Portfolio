import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';

/// The same page with some answers replaced.
extension SendCircleRequestCopy on SendCircleRequestState {
  SendCircleRequestState copyWith({
    String? phone,
    CircleAppMode? mode,
    bool? showErrors,
    SendStatus? status,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
    SentCircleRequest? sent,
  }) {
    return SendCircleRequestState(
      phone: phone ?? this.phone,
      mode: mode ?? this.mode,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
      sent: sent ?? this.sent,
    );
  }
}
