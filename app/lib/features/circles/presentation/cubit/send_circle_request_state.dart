import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:equatable/equatable.dart';

enum SendStatus { idle, sending, sent }

/// State of the page that asks a patient who uses the app for a circle (CREAT-04)
/// and of the waiting state that replaces it once the request is sent (CREAT-05).
class SendCircleRequestState extends Equatable {
  const SendCircleRequestState({
    this.phone = '',
    this.label = CircleLabel.mother,
    this.customLabel = '',
    this.mode = CircleAppMode.simplified,
    this.showErrors = false,
    this.status = SendStatus.idle,
    this.errorKey,
    this.sessionEnded = false,
    this.sent,
  });

  /// The nine digits after +966, written 0-9.
  final String phone;

  final CircleLabel label;
  final String customLabel;

  /// The mode proposed for the patient's app.
  final CircleAppMode mode;

  /// True after a tap on send with a missing answer.
  final bool showErrors;

  final SendStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  /// The request the server saved. Set once [status] is [SendStatus.sent].
  final SentCircleRequest? sent;

  SendCircleRequestState copyWith({
    String? phone,
    CircleLabel? label,
    String? customLabel,
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
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
      mode: mode ?? this.mode,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
      sent: sent ?? this.sent,
    );
  }

  @override
  List<Object?> get props => [
    phone,
    label,
    customLabel,
    mode,
    showErrors,
    status,
    errorKey,
    sessionEnded,
    sent,
  ];
}
