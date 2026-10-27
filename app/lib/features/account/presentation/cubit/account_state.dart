import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:equatable/equatable.dart';

enum AccountStatus { loading, ready, failure }

/// The question the page asks while the account is being deleted. The server
/// asks for a choice only when it matters, so the questions come one at a time.
enum DeletePrompt {
  none,

  /// "Delete your account?" The first and last question.
  confirm,

  /// The account is the patient of a circle: delete it or keep it.
  patientChoice,

  /// The account is the only manager of a circle: delete it too, or stop.
  lastManager,
}

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.loading,
    this.account,
    this.sent = const <SentCircleRequest>[],
    this.messageKey,
    this.errorKey,
    this.noticeKey,
    this.busyIds = const <String>{},
    this.deleting = false,
    this.deletePrompt = DeletePrompt.none,
    this.deletion = const AccountDeletion(),
    this.signedOut = false,
    this.sessionEnded = false,
  });

  final AccountStatus status;
  final AccountSummary? account;

  /// The requests this account sent that wait for the patient: pending ones,
  /// and accepted ones whose basic data is not finished.
  final List<SentCircleRequest> sent;

  /// Why the load failed: a key in assets/translations.
  final String? messageKey;

  /// Why the last action failed, shown once.
  final String? errorKey;

  /// What the last action achieved ("تم الحفظ"), shown once.
  final String? noticeKey;

  /// The ids of the requests that are being canceled now.
  final Set<String> busyIds;

  /// The account is being deleted.
  final bool deleting;
  final DeletePrompt deletePrompt;

  /// The choices made so far while deleting.
  final AccountDeletion deletion;

  /// The account was deleted and the tokens are gone: the page goes to sign-in.
  final bool signedOut;

  /// The server said the sign-in ended: the page goes to sign-in.
  final bool sessionEnded;

  AccountState copyWith({
    AccountStatus? status,
    AccountSummary? account,
    List<SentCircleRequest>? sent,
    String? messageKey,
    String? errorKey,
    String? noticeKey,
    bool clearMessages = false,
    Set<String>? busyIds,
    bool? deleting,
    DeletePrompt? deletePrompt,
    AccountDeletion? deletion,
    bool? signedOut,
    bool? sessionEnded,
  }) {
    return AccountState(
      status: status ?? this.status,
      account: account ?? this.account,
      sent: sent ?? this.sent,
      messageKey: messageKey ?? this.messageKey,
      errorKey: clearMessages ? null : (errorKey ?? this.errorKey),
      noticeKey: clearMessages ? null : (noticeKey ?? this.noticeKey),
      busyIds: busyIds ?? this.busyIds,
      deleting: deleting ?? this.deleting,
      deletePrompt: deletePrompt ?? this.deletePrompt,
      deletion: deletion ?? this.deletion,
      signedOut: signedOut ?? this.signedOut,
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    account,
    sent,
    messageKey,
    errorKey,
    noticeKey,
    busyIds,
    deleting,
    deletePrompt,
    deletion,
    signedOut,
    sessionEnded,
  ];
}
