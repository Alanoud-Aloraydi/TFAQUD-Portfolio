import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/home/domain/usecases/home_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum InboxStatus { loading, ready, failure }

/// What the notifications page and the bell show: the requests and invitations
/// that wait for an answer, read from the server.
class InboxState extends Equatable {
  const InboxState({
    this.status = InboxStatus.loading,
    this.inbox = const CircleInbox.empty(),
    this.messageKey,
    this.errorKey,
    this.busyIds = const <String>{},
    this.sessionEnded = false,
  });

  final InboxStatus status;
  final CircleInbox inbox;

  /// Why the first load failed: a key in assets/translations.
  final String? messageKey;

  /// Why the last answer failed: a key in assets/translations. The page shows
  /// it once and the list stays as it is.
  final String? errorKey;

  /// The ids of the requests and invitations that are being answered now.
  final Set<String> busyIds;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  InboxState copyWith({
    InboxStatus? status,
    CircleInbox? inbox,
    String? messageKey,
    String? errorKey,
    bool clearError = false,
    Set<String>? busyIds,
    bool? sessionEnded,
  }) {
    return InboxState(
      status: status ?? this.status,
      inbox: inbox ?? this.inbox,
      messageKey: messageKey ?? this.messageKey,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      busyIds: busyIds ?? this.busyIds,
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    inbox,
    messageKey,
    errorKey,
    busyIds,
    sessionEnded,
  ];
}

/// What the inbox is read with, shared by everything it does.
mixin InboxScope on Cubit<InboxState> {
  CirclesUseCase get circles;
  HomeUseCase get home;

  /// Counts the readings, so a slower one cannot overwrite a newer answer.
  int revision = 0;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
