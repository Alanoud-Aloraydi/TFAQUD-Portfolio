import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:equatable/equatable.dart';

/// What «حسابي» shows: the account, its circles and sent requests, and
/// where a sign-out or a deletion has got to.
class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.loading,
    this.account,
    this.circles = const <CareCircleSummary>[],
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

  /// The circles this account manages, for the calendar-sync circle
  /// picker: a manager may have more than one.
  final List<CareCircleSummary> circles;

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

  @override
  List<Object?> get props => accountStateProps(this);
}

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

/// Replacing some of the fields of an [AccountState].
extension AccountStateCopy on AccountState {
  AccountState copyWith({
    AccountStatus? status,
    AccountSummary? account,
    List<CareCircleSummary>? circles,
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
      circles: circles ?? this.circles,
      sent: sent ?? this.sent,
      messageKey: clearMessages ? null : (messageKey ?? this.messageKey),
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
}

/// What makes two [AccountState]s equal: every field, in the order the
/// class declares them.
List<Object?> accountStateProps(AccountState state) => <Object?>[
  state.status,
  state.account,
  state.circles,
  state.sent,
  state.messageKey,
  state.errorKey,
  state.noticeKey,
  state.busyIds,
  state.deleting,
  state.deletePrompt,
  state.deletion,
  state.signedOut,
  state.sessionEnded,
];
