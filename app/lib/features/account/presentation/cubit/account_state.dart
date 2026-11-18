export 'package:app/features/account/presentation/cubit/account_status.dart';
export 'package:app/features/account/presentation/cubit/delete_prompt.dart';
import 'package:app/features/account/presentation/cubit/account_state_props.dart';
import 'package:app/features/account/presentation/cubit/account_status.dart';
import 'package:app/features/account/presentation/cubit/delete_prompt.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:equatable/equatable.dart';
export 'package:app/features/account/presentation/cubit/account_state_copy.dart';

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
